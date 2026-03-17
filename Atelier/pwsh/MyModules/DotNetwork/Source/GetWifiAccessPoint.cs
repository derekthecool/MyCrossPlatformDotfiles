namespace DotNetwork;

using ManagedNativeWifi;

[Cmdlet("Get", "WifiAccessPoint")]
[Alias("gwap")]
public class GetWifiAccessPoint : PSCmdlet
{
    protected override void BeginProcessing()
    {
        WriteVerbose("Begin!");
    }

    protected override void ProcessRecord()
    {
        NativeWifi
            .EnumerateAvailableNetworks()
            .Where(x => !string.IsNullOrEmpty(x.Ssid.ToString()))
            .OrderByDescending(x => x.SignalQuality)
            .DistinctBy(x => x.Ssid)
            .ToList()
            .ForEach(WriteObject);
    }

    protected override void EndProcessing()
    {
        WriteVerbose("End!");
    }
}
