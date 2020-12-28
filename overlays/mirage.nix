# self: super:

# {
#   mirage-im = super.mirage-im.overrideAttrs ( old: {
#     preFixup = ''
#       buildPythonPath "$out $pythonPath"
#       wrapQtApp $out/bin/mirage \
#         --prefix PYTHONPATH : "$PYTHONPATH"
#     '';
#   });
# }

