# The API clients generated into Source/. Update-GeneratedClients.ps1 regenerates them from this table and the
# drift tests (Test/OpenApiGeneration/OpenApi.GeneratedClients.Tests.ps1) read it too, so adding a client here
# is all it takes to get it generated, exported from DotWebApi.psd1 and checked.
#
# Keys are client names (also the command prefix). Path and OutputPath are relative to the module root.
#
# Spec sources (fetched 2026-10-13, copied unmodified):
#   Frigate        MIT       https://github.com/blakeblackshear/frigate  docs/static/frigate-api.yaml @ b79e043
#   OpenFoodFacts  AGPL-3.0  https://github.com/openfoodfacts/openfoodfacts-server  docs/api/ref @ 58a0988 (the
#                            files api.yaml refers to; Source/OpenFoodFacts/spec/ holds only those)
#   OpenMeteo*     AGPL-3.0  https://github.com/open-meteo/open-meteo  openapi/*.yml @ 4633aa1
# The YAML specs need the powershell-yaml module (listed in Atelier/pwsh/Bootstrap-RequiredModules.ps1).
@{
    Kokoro                     = @{
        Path            = 'Source/Kokoro/kokoro_tts_openapi.json'
        OutputPath      = 'Source/Kokoro'
        DefaultEndpoint = 'http://192.168.1.103:8880'
        NameOverride    = @{
            'POST /dev/phonemize'              = 'ConvertTo-KokoroPhoneme'
            'POST /dev/generate_from_phonemes' = 'New-KokoroSpeechFromPhoneme'
        }
    }

    # Frigate NVR. The port is the one the Frigate UI/API listens on by default.
    Frigate                    = @{
        Path            = 'Source/Frigate/frigate-api.yaml'
        OutputPath      = 'Source/Frigate'
        DefaultEndpoint = 'http://192.168.1.91:5000'
        NameOverride    = @{
            'GET /'                                                          = 'Test-FrigateHealth'
            'GET /auth'                                                      = 'Test-FrigateAuthentication'
            'GET /logout'                                                    = 'Invoke-FrigateLogout'
            'GET /genai/roles'                                               = 'Get-FrigateGenAiRole'
            'GET /events/explore'                                            = 'Get-FrigateObjectSummary'
            'GET /events/summary'                                            = 'Get-FrigateEventSummary'
            'GET /review/event/{event_id}'                                   = 'Get-FrigateReviewByEventId'
            'GET /{camera_name}/recordings/summary'                          = 'Get-FrigateCameraRecordingsSummary'
            'GET /{camera_name}/{label}/best.jpg'                            = 'Get-FrigateLabelBestThumbnail'
            'GET /{camera_name}/{label}/thumbnail.jpg'                       = 'Get-FrigateLabelThumbnail'
            'GET /preview/{year_month}/{day}/{hour}/{camera_name}/{tz_name}' = 'Get-FrigatePreviewClipByHour'
            'PUT /camera/{camera_name}/set/{feature}'                        = 'Set-FrigateCameraFeature'
            'PUT /camera/{camera_name}/set/{feature}/{sub_command}'          = 'Set-FrigateCameraFeatureOption'
            'DELETE /notices/hidden'                                         = 'Restore-FrigateHiddenNotice'
            'DELETE /notices/{notice_id}/hidden'                             = 'Restore-FrigateNotice'
            'POST /events/{event_id}/plus'                                   = 'Send-FrigateEventToPlus'
        }
    }

    # Open Food Facts production. world.openfoodfacts.net is the staging server (see the spec's servers list).
    OpenFoodFacts              = @{
        Path            = 'Source/OpenFoodFacts/spec/api.yaml'
        OutputPath      = 'Source/OpenFoodFacts'
        DefaultEndpoint = 'https://world.openfoodfacts.org'
        NameOverride    = @{
            'GET /api/v2/product/{code}'          = 'Get-OpenFoodFactsProduct'
            'GET /api/v2/preferences'             = 'Get-OpenFoodFactsPreference'
            'GET /cgi/nutrients.pl'               = 'Get-OpenFoodFactsNutrient'
            'GET /cgi/ingredients.pl'             = 'Get-OpenFoodFactsIngredientOcr'
            'GET /cgi/product_image_crop.pl'      = 'Set-OpenFoodFactsProductImageRotation'
            'POST /cgi/product_image_crop.pl'     = 'Set-OpenFoodFactsProductImageCrop'
            'POST /cgi/product_image_unselect.pl' = 'Clear-OpenFoodFactsProductImageSelection'
            'POST /cgi/session.pl'                = 'New-OpenFoodFactsSession'
        }
    }

    # Open-Meteo publishes one spec per API, each on its own host, so each is its own client with its own
    # endpoint settings. The free host is the spec's first server; the second is the paid customer host.
    OpenMeteoAirQuality        = @{
        Path         = 'Source/OpenMeteo/spec/air-quality.yml'
        OutputPath   = 'Source/OpenMeteo'
        NameOverride = @{ 'GET /v1/air-quality' = 'Get-OpenMeteoAirQuality' }
    }
    OpenMeteoClimate           = @{
        Path         = 'Source/OpenMeteo/spec/climate.yml'
        OutputPath   = 'Source/OpenMeteo'
        NameOverride = @{ 'GET /v1/climate' = 'Get-OpenMeteoClimate' }
    }
    OpenMeteoElevation         = @{
        Path         = 'Source/OpenMeteo/spec/elevation.yml'
        OutputPath   = 'Source/OpenMeteo'
        NameOverride = @{ 'GET /v1/elevation' = 'Get-OpenMeteoElevation' }
    }
    OpenMeteoEnsemble          = @{
        Path         = 'Source/OpenMeteo/spec/ensemble.yml'
        OutputPath   = 'Source/OpenMeteo'
        NameOverride = @{ 'GET /v1/ensemble' = 'Get-OpenMeteoEnsemble' }
    }
    OpenMeteoFlood             = @{
        Path         = 'Source/OpenMeteo/spec/flood.yml'
        OutputPath   = 'Source/OpenMeteo'
        NameOverride = @{ 'GET /v1/flood' = 'Get-OpenMeteoFlood' }
    }
    OpenMeteoForecast          = @{
        Path         = 'Source/OpenMeteo/spec/forecast.yml'
        OutputPath   = 'Source/OpenMeteo'
        NameOverride = @{ 'GET /v1/forecast' = 'Get-OpenMeteoForecast' }
    }
    OpenMeteoHistoricalWeather = @{
        Path         = 'Source/OpenMeteo/spec/historical-weather.yml'
        OutputPath   = 'Source/OpenMeteo'
        NameOverride = @{ 'GET /v1/archive' = 'Get-OpenMeteoHistoricalWeather' }
    }
    OpenMeteoMarine            = @{
        Path         = 'Source/OpenMeteo/spec/marine.yml'
        OutputPath   = 'Source/OpenMeteo'
        NameOverride = @{ 'GET /v1/marine' = 'Get-OpenMeteoMarine' }
    }
    OpenMeteoSeasonal          = @{
        Path         = 'Source/OpenMeteo/spec/seasonal.yml'
        OutputPath   = 'Source/OpenMeteo'
        NameOverride = @{ 'GET /v1/seasonal' = 'Get-OpenMeteoSeasonal' }
    }
}
