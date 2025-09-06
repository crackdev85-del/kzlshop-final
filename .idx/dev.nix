{
  pkgs, 
  ...
}: {
  channel = "stable-23.11";
  
  environment.systemPackages = [
    pkgs.flutter
    pkgs.dart
    pkgs.git
    pkgs.gh
    pkgs.zulu
    pkgs.gradle
  ];
  
  environment.variables = {
    JAVA_HOME = "${pkgs.zulu}";
    GRADLE_HOME = "${pkgs.gradle}";
    PATH = "$PATH:${pkgs.gradle}/bin";
  };
  
  services.ports = [
    {
      port = 8080;
      onOpen = "ignore";
    }
    {
      port = 9100;
      onOpen = "ignore";
      visibility = "private";
    }
  ];
  
  workspace.onStart = {
    flutter-doctor = "flutter doctor";
    start-flutter = "flutter run --web-port 6006";
  };
  
  previews = {
    enable = true;
    previews = [
      {
        port = 6006;
      }
    ];
  };
}