--
-- VXLAN and Network Service Header Dissector
-- https://tools.ietf.org/html/draft-ietf-sfc-nsh-00
--
-- copy this file to ~/.wireshark/plugins/
--

do
    local protocol_vxlan = Proto("vxlan1", "VxLAN");
    local vxlan_flags = ProtoField.uint8("vxlan.flags","Flags",base.HEX)
    local vxlan_flag_i = ProtoField.bool("vxlan.flags.i","I Flag",8,
                {"Valid VNI Tag present", "Valid VNI Tag NOT present"}, 0x08)
    local vxlan_reserved1 = ProtoField.uint24("vxlan.reserved1","Reserved", base.HEX)
    local vxlan_vni = ProtoField.uint24("vxlan.vni","VNI",base.HEX)
    local vxlan_reserved2 = ProtoField.uint8("vxlan.reserved2","Reserved", base.HEX)

    protocol_vxlan.fields = {vxlan_flags, vxlan_flag_i, vxlan_reserved1,
                             vxlan_vni, vxlan_reserved2}

    local protocol_nsh = Proto("nsh","Network Service Header");
    local nsh_flags = ProtoField.uint16("nsh.flags","Flags",base.HEX)
    local nsh_flag_version = ProtoField.uint16("nsh.flags.version","Version",
        base.DEC, nil, 0xC000)
    local nsh_flag_o = ProtoField.bool("nsh.flags.o","O Flag", 16,
        {"Valid OAM Bit present", "Valid OAM Bit NOT present"}, 0x2000)
    local nsh_flag_c = ProtoField.bool("nsh.flags.c","C Flag", 16,
        {"Valid Context Bit present", "Valid Context Bit NOT present"}, 0x1000)
    local nsh_flag_reserved = ProtoField.uint16("nsh.flags.reserved","Reserved",
        base.DEC, nil, 0x00FC0)
    local nsh_flag_length = ProtoField.uint16("nsh.flags.length","Length",
        base.DEC, nil, 0x0003F)
    local nsh_md_type = ProtoField.uint8("nsh.md_type","MD Type", base.HEX)
    local nsh_next_proto_type = ProtoField.uint8("nsh.next_proto_type",
        "Next Protocol Type", base.HEX)
    local nsh_service_path_id = ProtoField.uint24("nsh.service_path_id","Service Path",
        base.HEX)
    local nsh_service_index = ProtoField.uint8("nsh.service_index","Service Index",
        base.HEX)
    local nsh_net_plt_ctx = ProtoField.uint32("nsh.net_plt_ctx",
        "NSH Context C1",base.HEX)
    local nsh_net_shd_ctx = ProtoField.uint32("nsh.net_shd_ctx",
        "NSH Context C2",base.HEX)
    local nsh_svc_plt_ctx = ProtoField.uint32("nsh.svc_plt_ctx",
        "NSH Context C3",base.HEX)
    local nsh_svc_shd_ctx = ProtoField.uint32("nsh.svc_shd_ctx",
        "NSH Context C4",base.HEX)

    protocol_nsh.fields = {nsh_flags, nsh_flag_version, nsh_flag_o, nsh_flag_c,
        nsh_flag_reserved, nsh_flag_length, nsh_md_type, nsh_next_proto_type,
        nsh_service_index, nsh_service_path_id, nsh_net_plt_ctx, nsh_net_shd_ctx,
        nsh_svc_plt_ctx, nsh_svc_shd_ctx}

    function protocol_vxlan.dissector(buf, pinfo, root)
        local t = root:add(protocol_vxlan, buf(0,8))
        local f = t:add(vxlan_flags, buf(0,1))

        f:add(vxlan_flag_i, buf(0,1))
        t:add(vxlan_reserved1, buf(1,3))
        t:add(vxlan_vni, buf(4,3))
        t:add(vxlan_reserved2, buf(7,1))
        t:append_text(", VNI: 0x" .. string.format("%x",
            buf(4, 3):uint()))

        local eth_dis = Dissector.get("eth")
        eth_dis:call(buf(8):tvb(), pinfo, root)
    end

    function protocol_nsh.dissector(buf, pinfo, root)
        local t = root:add(protocol_vxlan, buf(0,8))
        local f = t:add(vxlan_flags, buf(0,1))

        f:add(vxlan_flag_i, buf(0,1))
        t:add(vxlan_reserved1, buf(1,3))
        t:add(vxlan_vni, buf(4,3))
        t:add(vxlan_reserved2, buf(7,1))
        t:append_text(", VNI: 0x" .. string.format("%x",
            buf(4, 3):uint()))

        local nsh_t = root:add(protocol_nsh, buf(8,24))
        local nsh_f = nsh_t:add(nsh_flags, buf(8,2))

        nsh_f:add(nsh_flag_version, buf(8,2))
        nsh_f:add(nsh_flag_o, buf(8,2))
        nsh_f:add(nsh_flag_c, buf(8,2))
        nsh_f:add(nsh_flag_reserved, buf(8,2))
        nsh_f:add(nsh_flag_length, buf(8,2))

        nsh_t:add(nsh_md_type, buf(10,1))
        nsh_t:add(nsh_next_proto_type, buf(11,1))
        nsh_t:add(nsh_service_path_id, buf(12,3))
        nsh_t:add(nsh_service_index, buf(15,1))

        nsh_t:add(nsh_net_plt_ctx, buf(16,4))
        nsh_t:add(nsh_net_shd_ctx, buf(20,4))
        nsh_t:add(nsh_svc_plt_ctx, buf(24,4))
        nsh_t:add(nsh_svc_shd_ctx, buf(28,4))

        nsh_t:append_text(", Version: " .. string.format("%d",
            buf(8, 1):bitfield(0,2)))
        nsh_t:append_text(", Next Protocol: 0x" .. string.format("%x",
            buf(11, 1):uint()))
        nsh_t:append_text(", Service Path ID: 0x" .. string.format("%x",
            buf(12, 3):uint()))
        nsh_t:append_text(", Service Index: 0x" .. string.format("%x",
            buf(15, 1):uint()))

        local eth_dis = Dissector.get("eth")
        eth_dis:call(buf(32):tvb(), pinfo, root)
    end

    local udp_encap_table = DissectorTable.get("udp.port")
    udp_encap_table:add(4789, protocol_vxlan)
    udp_encap_table:add(6633, protocol_nsh)
end
