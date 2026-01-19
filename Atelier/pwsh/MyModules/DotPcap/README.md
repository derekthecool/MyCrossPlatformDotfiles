# DotPcap

## tshark parsing

the tshark wireshark command line tool can do a great job parsing pcap files.
However, the json format/object produced is ugly. Here is an example of a single parsed packet object:

```json
[
  {
    "_index": "packets-2025-12-16",
    "_type": "doc",
    "_score": null,
    "_source": {
      "layers": {
        "frame": {
          "frame.encap_type": "7",
          "frame.time": "Dec 16, 2025 15:01:17.614542000 Mountain Standard Time",
          "frame.time_utc": "Dec 16, 2025 22:01:17.614542000 UTC",
          "frame.time_epoch": "1765922477.614542000",
          "frame.offset_shift": "0.000000000",
          "frame.time_delta": "0.000000000",
          "frame.time_delta_displayed": "0.000000000",
          "frame.time_relative": "0.000000000",
          "frame.number": "1",
          "frame.len": "92",
          "frame.cap_len": "92",
          "frame.marked": "0",
          "frame.ignored": "0",
          "frame.protocols": "raw:ip:icmp:data"
        },
        "raw": "Raw packet data",
        "ip": {
          "ip.version": "4",
          "ip.hdr_len": "20",
          "ip.dsfield": "0x00",
          "ip.dsfield_tree": {
            "ip.dsfield.dscp": "0",
            "ip.dsfield.ecn": "0"
          },
          "ip.len": "92",
          "ip.id": "0xf3de",
          "ip.flags": "0x00",
          "ip.flags_tree": {
            "ip.flags.rb": "0",
            "ip.flags.df": "0",
            "ip.flags.mf": "0"
          },
          "ip.frag_offset": "0",
          "ip.ttl": "59",
          "ip.proto": "1",
          "ip.checksum": "0x651b",
          "ip.checksum.status": "2",
          "ip.src": "10.216.10.88",
          "ip.addr": "10.216.10.88",
          "ip.src_host": "10.216.10.88",
          "ip.host": "10.216.10.88",
          "ip.dst": "10.100.7.20",
          "ip.addr": "10.100.7.20",
          "ip.dst_host": "10.100.7.20",
          "ip.host": "10.100.7.20",
          "ip.stream": "0"
        },
        "icmp": {
          "icmp.type": "0",
          "icmp.code": "0",
          "icmp.checksum": "0x66cb",
          "icmp.checksum.status": "1",
          "icmp.ident": "35848",
          "icmp.ident_le": "2188",
          "icmp.seq": "256",
          "icmp.seq_le": "1",
          "data": {
            "data.data": "41:42:43:44:45:46:47:48:49:4a:4b:4c:4d:4e:4f:50:51:52:53:54:55:56:57:58:59:5a:5b:5c:5d:5e:5f:60:61:62:63:64:65:66:67:68:69:6a:6b:6c:6d:6e:6f:70:71:72:73:74:75:76:77:78:79:7a:7b:7c:7d:7e:7f:80",
            "data.len": "64"
          }
        }
      }
    }
  }
]
```

The only good stuff is contained in the `_source.layers` the rest is bad.
