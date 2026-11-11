{
  lib,
  stdenvNoCC,
  imagemagick,
  style,
}:

let
  inherit (style) colors spacing layout;

  # Plymouth scripts take colors as three floats from 0 to 1.
  floats =
    color:
    let
      hex = lib.removePrefix "#" color;
      channel = start: toString (lib.fromHexString (builtins.substring start 2 hex) / 255.0);
    in
    "${channel 0}, ${channel 2}, ${channel 4}";

  # The password field matches hyprlock's. Sizes are in pixels at 1x.
  field = {
    width = 320;
    height = 44;
  };
  bullet = spacing.md;

  font = size: "${style.font.mono} ${toString size}";

  script = ''
    Window.SetBackgroundTopColor(${floats colors.desktop});
    Window.SetBackgroundBottomColor(${floats colors.desktop});

    # Plymouth runs with DeviceScale=1, so pick the 2x images on wide panels.
    scale = 1;
    if (Window.GetWidth() >= 2400) scale = 2;
    suffix = "";
    if (scale == 2) suffix = "@2x";

    center_x = Window.GetX() + Window.GetWidth() / 2;
    center_y = Window.GetY() + Window.GetHeight() / 2;

    field.image = Image("field" + suffix + ".png");
    field.sprite = Sprite(field.image);
    field.x = center_x - field.image.GetWidth() / 2;
    field.y = center_y - field.image.GetHeight() / 2;
    field.sprite.SetPosition(field.x, field.y, 1);
    field.sprite.SetOpacity(0);

    bullet.image = Image("bullet" + suffix + ".png");
    bullet.gap = ${toString spacing.sm} * scale;
    bullet.y = center_y - bullet.image.GetHeight() / 2;
    bullet.max = Math.Int((field.image.GetWidth() - 2 * ${toString spacing.lg} * scale) / (bullet.image.GetWidth() + bullet.gap));

    prompt.sprite = Sprite();
    prompt.sprite.SetOpacity(0);
    message.sprite = Sprite();
    message.sprite.SetOpacity(0);

    fun show_text(target, text, r, g, b, y) {
      target.image = Image.Text(text, r, g, b, 1, "${font style.fontSize.small}");
      if (scale == 2) target.image = target.image.Scale(target.image.GetWidth() * 2, target.image.GetHeight() * 2);
      target.sprite.SetImage(target.image);
      target.sprite.SetPosition(center_x - target.image.GetWidth() / 2, y, 2);
      target.sprite.SetOpacity(1);
    }

    fun hide_bullets(from) {
      for (i = from; global.bullets[i]; i++)
        global.bullets[i].SetOpacity(0);
    }

    fun display_normal_callback() {
      field.sprite.SetOpacity(0);
      prompt.sprite.SetOpacity(0);
      hide_bullets(0);
    }

    fun display_password_callback(text, count) {
      field.sprite.SetOpacity(1);
      show_text(prompt, text, ${floats colors.muted}, field.y - ${toString spacing.xl} * scale * 2);

      shown = Math.Min(count, bullet.max);
      width = shown * bullet.image.GetWidth() + (shown - 1) * bullet.gap;
      for (i = 0; i < shown; i++) {
        if (!global.bullets[i])
          global.bullets[i] = Sprite(bullet.image);
        global.bullets[i].SetPosition(center_x - width / 2 + i * (bullet.image.GetWidth() + bullet.gap), bullet.y, 3);
        global.bullets[i].SetOpacity(1);
      }
      hide_bullets(shown);
    }

    fun message_callback(text) {
      show_text(message, text, ${floats colors.muted}, field.y + field.image.GetHeight() + ${toString spacing.xl} * scale);
    }

    Plymouth.SetDisplayNormalFunction(display_normal_callback);
    Plymouth.SetDisplayPasswordFunction(display_password_callback);
    Plymouth.SetMessageFunction(message_callback);
  '';
in
stdenvNoCC.mkDerivation {
  pname = "plymouth-theme-chena";
  version = "1";

  dontUnpack = true;

  nativeBuildInputs = [ imagemagick ];

  passAsFile = [ "script" ];
  inherit script;

  buildPhase = ''
    runHook preBuild

    image() {
      local scale=$1 suffix=$2
      local width=$(( ${toString field.width} * scale )) height=$(( ${toString field.height} * scale ))
      local border=$(( ${toString layout.border} * scale ))
      magick -size ''${width}x''${height} 'xc:${colors.border}' \
        -fill '${colors.surface}' \
        -draw "rectangle $border,$border $(( width - border - 1 )),$(( height - border - 1 ))" \
        field$suffix.png
      local dot=$(( ${toString bullet} * scale ))
      magick -size ''${dot}x''${dot} 'xc:${colors.accent}' bullet$suffix.png
    }
    image 1 ""
    image 2 "@2x"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    dir=$out/share/plymouth/themes/chena
    mkdir -p $dir
    cp field.png field@2x.png bullet.png bullet@2x.png $dir/
    cp $scriptPath $dir/chena.script
    cat > $dir/chena.plymouth <<EOF
    [Plymouth Theme]
    Name=chena
    Description=The chena desktop theme
    ModuleName=script

    [script]
    ImageDir=$dir
    ScriptFile=$dir/chena.script
    EOF

    runHook postInstall
  '';
}
