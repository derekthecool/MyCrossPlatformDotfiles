# Function designed to basically be like dotnet watch
if($IsWindows) {
    # This function sets all the build environment for ESP-IDF
    function Source-Espidf() {
        # Customize these for your install path and version
        $version = '5.0.1'
        $root_location = 'D:\'

        # Set environment variable
        $env:IDF_PATH = "${root_location}Espressif\frameworks\esp-idf-v${version}"

        # Run the setup script
        Invoke-Expression "${root_location}Espressif/Initialize-Idf.ps1"
    }
}
