# Mic for games streamed through Moonshine.
#
# Moonshine runs games against its own built-in PulseAudio server, which only
# has a sink, so games can't record. Instead:
# - surface sends its mic over RTP (programs/moonlight), received here as the
#   source "moonshine-mic" in the desktop PipeWire
# - the Steam launch option `moonshine-mic %command%` points a game at the
#   desktop PipeWire with "moonshine-mic" as its default source, but only
#   under Moonshine. For as long as the game runs it also starts "moonshine-out",
#   a sink that tunnels into Moonshine's server so the stream still gets the
#   game audio. The tunnel can't live in the main PipeWire config: a tunnel
#   that fails to connect is fatal there and takes PipeWire down with it.
{pkgs, ...}: let
  port = 46000;

  moonshineMic = pkgs.writeShellScriptBin "moonshine-mic" ''
    if [[ ''${PULSE_SERVER-} != *moonshine* ]]; then
      exec "$@"
    fi

    conf=$XDG_RUNTIME_DIR/moonshine-out.conf
    cat > "$conf" <<EOF
    context.spa-libs = {
      audio.convert.* = audioconvert/libspa-audioconvert
      support.*       = support/libspa-support
    }
    context.modules = [
      { name = libpipewire-module-rt flags = [ ifexists nofail ] }
      { name = libpipewire-module-protocol-native }
      { name = libpipewire-module-client-node }
      { name = libpipewire-module-adapter }
      { name = libpipewire-module-pulse-tunnel
        args = {
          tunnel.mode = sink
          pulse.server.address = "$PULSE_SERVER"
          # 30 ms popped: too little headroom over the 21 ms graph quantum
          pulse.latency = 80
          reconnect.interval.ms = 2000
          stream.props = {
            node.name = "moonshine-out"
            node.description = "Moonshine stream"
          }
        }
      }
    ]
    EOF
    ${pkgs.pipewire}/bin/pipewire -c "$conf" &
    tunnel=$!
    trap 'kill $tunnel 2>/dev/null' EXIT

    export PULSE_SERVER="unix:$XDG_RUNTIME_DIR/pulse/native"
    export PULSE_SINK=moonshine-out PULSE_SOURCE=moonshine-mic
    unset PULSE_RUNTIME_PATH

    # the game must not open its audio before the sink exists
    for _ in $(seq 50); do
      ${pkgs.pipewire}/bin/pw-cli ls Node | grep -q '"moonshine-out"' && break
      sleep 0.1
    done

    "$@"
  '';
in {
  xdg.configFile."pipewire/pipewire.conf.d/60-moonshine-mic.conf".text = ''
    context.modules = [
      { name = libpipewire-module-rtp-source
        args = {
          source.ip = "0.0.0.0"
          source.port = ${toString port}
          sess.latency.msec = 60
          # the sender restarts with Moonlight and picks a new SSRC
          sess.ignore-ssrc = true
          # keep the socket open while nothing records, or the sender gets
          # ICMP port unreachable and the first packets are lost
          node.always-process = true
          audio.format = "S16BE"
          audio.rate = 48000
          stream.props = {
            media.class = "Audio/Source"
            node.name = "moonshine-mic"
            node.description = "Moonlight mic"
          }
        }
      }
    ]
  '';

  home.packages = [moonshineMic];
}
