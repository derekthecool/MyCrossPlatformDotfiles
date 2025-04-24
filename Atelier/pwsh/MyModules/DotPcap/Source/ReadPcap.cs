namespace DotPcap;

using System.IO;
using PacketDotNet;
using SharpPcap;
using SharpPcap.LibPcap;

[Cmdlet("Read", "Pcap")]
// [OutputType(typeof(RawCapture))]
public class ReadPcap : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true)]
    public string[] Path { get; set; }

    private static int packetIndex = 0;

    protected override void BeginProcessing()
    {
        packetIndex = 0;
    }

    // This method will be called for each input received from the pipeline to this cmdlet; if no input is received, this method is not called
    protected override void ProcessRecord()
    {
        foreach (var CurrentPath in Path)
        {
            if (File.Exists(CurrentPath) == false)
            {
                throw new FileNotFoundException($"The file {CurrentPath} does not exist");
            }

            void Device_OnPacketArrival(object s, PacketCapture e)
            {
                packetIndex++;

                var rawPacket = e.GetPacket();
                var packet = PacketDotNet.Packet.ParsePacket(
                    rawPacket.LinkLayerType,
                    rawPacket.Data
                );

                var ethernetPacket = packet.Extract<EthernetPacket>();
                if (ethernetPacket != null)
                {
                    WriteObject(
                        new
                        {
                            Index = packetIndex,
                            Date = e.Header.Timeval.Date,
                            // e.Header.Timeval.Date.Millisecond,
                            HardwareAddress = ethernetPacket.SourceHardwareAddress,
                            DestinationAddress = ethernetPacket.DestinationHardwareAddress,
                        }
                    );
                }
            }

            using var device = new CaptureFileReaderDevice(CurrentPath);
            device.Open();
            device.OnPacketArrival += Device_OnPacketArrival;
            device.Capture();
        }
    }
}
