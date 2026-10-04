# Moonlight client with mic passthrough.
#
# GameStream has no mic channel, so while Moonlight runs a separate PipeWire
# client sends the default source to kaine over RTP. kaine turns it back into
# a source for the streamed game, see services/moonshine-mic.
{pkgs, ...}: let
  host = "192.168.178.67"; # kaine
  port = 46000;

  micConf = pkgs.writeText "moonlight-mic.conf" ''
    context.spa-libs = {
      audio.convert.* = audioconvert/libspa-audioconvert
      support.*       = support/libspa-support
    }
    context.modules = [
      { name = libpipewire-module-rt flags = [ ifexists nofail ] }
      { name = libpipewire-module-protocol-native }
      { name = libpipewire-module-client-node }
      { name = libpipewire-module-adapter }
      { name = libpipewire-module-rtp-sink
        args = {
          destination.ip = "${host}"
          destination.port = ${toString port}
          sess.name = "moonlight-mic"
          audio.format = "S16BE"
          audio.rate = 48000
          # The sink is a capture stream, so WirePlumber links it straight
          # to the default source; no loopback needed.
          stream.props = {
            node.name = "moonlight-mic-rtp"
            node.description = "Moonlight mic (RTP)"
          }
        }
      }
    ]
  '';

  moonlight = pkgs.writeShellScript "moonlight" ''
    ${pkgs.pipewire}/bin/pipewire -c ${micConf} &
    mic=$!
    trap 'kill $mic' EXIT
    ${pkgs.moonlight-qt}/bin/moonlight "$@"
  '';
in {
  home.packages = [
    (pkgs.symlinkJoin {
      name = "moonlight-qt-mic";
      paths = [pkgs.moonlight-qt];
      postBuild = ''
        rm $out/bin/moonlight
        ln -s ${moonlight} $out/bin/moonlight
      '';
    })
  ];
}
