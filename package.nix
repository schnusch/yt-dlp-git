{
  lib,
  stdenvNoCC,
  git,
  makeWrapper,
  python3,
  systemd,
  yt-dlp,
  plugins ? [ ],
}:

stdenvNoCC.mkDerivation {
  name = "yt-dlp.git";
  version = "0.1";

  src = lib.sourceByRegex ./. [
    "^bin(/.*)?$"
    "^lib(/.*)?$"
    "^libexec(/.*)?$"
  ];

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib/systemd/user" "$out/libexec"

    cp bin/yt-dlp "$out/bin/yt-dlp"
    wrapProgram "$out/bin/yt-dlp" --prefix PATH : "$out/libexec":${lib.makeBinPath [ systemd ]}

    substitute lib/systemd/user/yt-dlp-update.service "$out/lib/systemd/user/yt-dlp-update.service" \
        --replace-fail /usr/local "$out"

    cp libexec/update-yt-dlp "$out/libexec/update-yt-dlp"
    makeWrapper ${lib.getExe (python3.withPackages (ps: yt-dlp.dependencies))} "$out"/libexec/python3 ${
      lib.concatStringsSep " " (
        yt-dlp.makeWrapperArgs
        ++ lib.optionals (plugins != [ ]) [
          "--suffix"
          "PYTHONPATH"
          ":"
          (lib.makeSearchPathOutput "lib" python3.sitePackages plugins)
        ]
      )
    }

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/schnusch/yt-dlp-git";
    description = "Per-user auto-updated yt-dlp installation";
    license = licenses.unlicense;
  };
}
