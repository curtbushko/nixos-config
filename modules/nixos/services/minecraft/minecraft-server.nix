{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.services.minecraft;

  # Modpack configuration using linkFarmFromDrvs
  # All mods are fetched individually and linked together
  modpack = pkgs.linkFarmFromDrvs "modpack-mods" [
    # Xaeros_Minimap_25.2.10_Fabric_1.21.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/1bokaNcj/versions/IaH8q5hM/Xaeros_Minimap_25.2.10_Fabric_1.21.jar";
      sha512 = "7702b6a4cd94b7e80e8d381f2d620acc69467ab4df45cd9a4d37d2484dd8b0c3b0048a6be3bec16926b562891c38c0543316cda295a57cb27caad9e9de8a6362";
      name = "Xaeros_Minimap_25.2.10_Fabric_1.21.jar";
    })
    # YungsBetterEndIsland-1.21.1-Fabric-3.1.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/2BwBOmBQ/versions/zpUYcjIg/YungsBetterEndIsland-1.21.1-Fabric-3.1.2.jar";
      sha512 = "b26e84469e6d66bbc2deefec0b6ed7d93db2b374d7c4bb495e7178e668efb320a5793b42c1b0dd08f71513a4c25faee881e8d81b64eadacb1c34af1619a0f6cf";
      name = "YungsBetterEndIsland-1.21.1-Fabric-3.1.2.jar";
    })
    # shulkerboxtooltip-fabric-5.1.8+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/2M01OLQq/versions/nGPvABlf/shulkerboxtooltip-fabric-5.1.8%2B1.21.1.jar";
      sha512 = "b0b79aae60a2f88ac88ceb7bf114f7e1ce7701586da6b1acbd9d6f4e1d11d71dcc68e20e5f5cf5840832eabcb614f710a621bbe806eee9effeb9d778e122f1a4";
      name = "shulkerboxtooltip-fabric-5.1.8+1.21.1.jar";
    })
    # lambdabettergrass-2.0.4+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/2Uev7LdA/versions/WdPLwaZg/lambdabettergrass-2.0.4%2B1.21.1.jar";
      sha512 = "f4c001f463a9a04bc2b197638f53628c446c9f7061d7b23b2dd11931dc32b0368bdf1ab9263c5f24fbd03cf50f74614b3901cd45202162073c26cf2d000498d3";
      name = "lambdabettergrass-2.0.4+1.21.1.jar";
    })
    # YungsBetterOceanMonuments-1.21.1-Fabric-4.1.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/3dT9sgt4/versions/TGK6gpeO/YungsBetterOceanMonuments-1.21.1-Fabric-4.1.2.jar";
      sha512 = "2ad568affe005aa49be225ca1ce43272d773140dee7053ee4a5981288b5ef7ee92536a1d041ae3f00b6399de2f499abd1bf905cfbb764d569a99dd9b2cf8841f";
      name = "YungsBetterOceanMonuments-1.21.1-Fabric-4.1.2.jar";
    })
    # easyelytratakeoff-1.21.1-4.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/3hqwGCUB/versions/7JjYvNu3/easyelytratakeoff-1.21.1-4.5.jar";
      sha512 = "af9f857201d552e2bad771e8fad60140a5b6fb54c9f8e7b209fe92579a03287442f07e9f920707090780e6c0e17cfefb837eab82e77317a8d60646e4b330fd64";
      name = "easyelytratakeoff-1.21.1-4.5.jar";
    })
    # rogues-fabric-2.6.4+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/3MKqoGuP/versions/DWWYl1qC/rogues-fabric-2.6.4%2B1.21.1.jar";
      sha512 = "59409e24a87196525d543a51e2b4448010957a0a5643b3c47f430cff733c4d947030d7f9c61b8a32efe3136284824303bcb209ebd6e4541f451f6cdb3a39cae5";
      name = "rogues-fabric-2.6.4+1.21.1.jar";
    })
    # entity_model_features_1.21-fabric-3.0.9.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/4I1XuqiY/versions/tCUoahyn/entity_model_features_1.21-fabric-3.0.9.jar";
      sha512 = "65d02831ea0b8251173b2e863ca29472e74b7f07a7086d4ed296c1a22fe39099a1e431d0afc16199e1441beaf4dda5e8e2eb6b92e24115b9a964554ec2f4df8f";
      name = "entity_model_features_1.21-fabric-3.0.9.jar";
    })
    # moreculling-fabric-1.21.1-1.0.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/51shyZVL/versions/1V6UtDhN/moreculling-fabric-1.21.1-1.0.6.jar";
      sha512 = "c6a6db1e2b63084457358171175ddf6061b32d31843f982001720c34433ae96cb13d72b910dc486ad1556e9db55352df3619f131c733bf843d3273d248989b05";
      name = "moreculling-fabric-1.21.1-1.0.6.jar";
    })
    # piglinnames-1.21.1-1.3.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/54plduvG/versions/7KMoV9Oz/piglinnames-1.21.1-1.3.jar";
      sha512 = "c67b11a6996a848c4b165a89c637d20a35bc9c80e8e65c1537ad2042d5d6f1ede0becfd4a5acdbe86f178e356495b6340acf7cc764a87fb7fdcbab218ff29126";
      name = "piglinnames-1.21.1-1.3.jar";
    })
    # trinkets-3.10.0.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/5aaWibi9/versions/JagCscwi/trinkets-3.10.0.jar";
      sha512 = "3ea846c945a0559696501ff65b373c8ee8fd9b394604e9910b4ed710c3e07cadc674a615a2c3b385951a42253a418201975df951b3100053ed39afadc70221c9";
      name = "trinkets-3.10.0.jar";
    })
    # bettercombat-fabric-2.3.1+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/5sy6g3kz/versions/zZCcohvX/bettercombat-fabric-2.3.1%2B1.21.1.jar";
      sha512 = "e006007643dd2736a22a80d17e36fb2dd1cbe6c2799976d945165f04e828603979ec769358541e51168b7d50491e303f29ed9415eefa8497561e29df1dc9e4ad";
      name = "bettercombat-fabric-2.3.1+1.21.1.jar";
    })
    # ImmediatelyFast-Fabric-1.6.9+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/5ZwdcRci/versions/sy5ig8EF/ImmediatelyFast-Fabric-1.6.9%2B1.21.1.jar";
      sha512 = "b343af838639d63856ca1cb22e9643188a12160ba040624a7052ab61f3f53155aea046a3c824bf06d5b1b87af25193552111676fe659bb1acc04909d6051ff96";
      name = "ImmediatelyFast-Fabric-1.6.9+1.21.1.jar";
    })
    # geckolib-fabric-1.21.1-4.8.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/8BmcQJ2H/versions/fHBvu50G/geckolib-fabric-1.21.1-4.8.2.jar";
      sha512 = "6a82ec0ab222838daecbbc2e2ad8347057a5078b038f071a9791e75a2510e0f84be2f247102b0b3c1d9e96d89fedb81b77741786f6250a2c7b96655a49ad4f96";
      name = "geckolib-fabric-1.21.1-4.8.2.jar";
    })
    # spell_power-fabric-1.4.6+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/8ooWzSQP/versions/QNQTJZnp/spell_power-fabric-1.4.6%2B1.21.1.jar";
      sha512 = "1867049bd921df122d8455cda34d545bd908e3f69d0ded2fb5ab471835531b049fd59917b61d1402fd4c6e5b74e5d699220917dd5201641995fb7c48c68b7b71";
      name = "spell_power-fabric-1.4.6+1.21.1.jar";
    })
    # Ribbits-1.21.1-Fabric-4.1.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/8YcE8y4T/versions/O3uPSYcc/Ribbits-1.21.1-Fabric-4.1.6.jar";
      sha512 = "00829624b226afbf75587d4cfdb8cbefaefec55acaa7aad4aae70f65fdf1cbe3edfc61bb2cf28c41d96a6b20ba0dad52dadb35dd21378ff28b39cf42f238662e";
      name = "Ribbits-1.21.1-Fabric-4.1.6.jar";
    })
    # voicechat-fabric-1.21.1-2.6.10.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/9eGKb6K1/versions/eLYuxqom/voicechat-fabric-1.21.1-2.6.10.jar";
      sha512 = "208cbe5993486c43688b3a329c146ff8fbf0395f061f8afbae82fed969ba16b6b685e440602adcde23bfb09f8f67e638ebfd097ac78203f8e34ca6234137adb6";
      name = "voicechat-fabric-1.21.1-2.6.10.jar";
    })
    # cloth-config-15.0.140-fabric.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/9s6osm5g/versions/HpMb5wGb/cloth-config-15.0.140-fabric.jar";
      sha512 = "1b3f5db4fc1d481704053db9837d530919374bf7518d7cede607360f0348c04fc6347a3a72ccfef355559e1f4aef0b650cd58e5ee79c73b12ff0fc2746797a00";
      name = "cloth-config-15.0.140-fabric.jar";
    })
    # sodium-fabric-0.6.13+mc1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/AANobbMI/versions/u1OEbNKx/sodium-fabric-0.6.13%2Bmc1.21.1.jar";
      sha512 = "13032e064c554fc8671573dadb07bc70e6ea2f68706c65c086c4feb1d2f664346a3414cbf9d1367b42b8d063a35e40f2f967ef9af31642e1f0093b852161fe91";
      name = "sodium-fabric-0.6.13+mc1.21.1.jar";
    })
    # treeharvester-1.21.1-9.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/abooMhox/versions/OtzwmSlR/treeharvester-1.21.1-9.1.jar";
      sha512 = "ef05666db209bcc339a89c83106c329a51d32310188f913375d8ebb3ff98251f99ae21baa6def18e1125d64e5d454f6cd5c5dbe7f8ddc00312dfa1b89a866c4d";
      name = "treeharvester-1.21.1-9.1.jar";
    })
    # MouseTweaks-fabric-mc1.21-2.26.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/aC3cM3Vq/versions/ylmBQ38A/MouseTweaks-fabric-mc1.21-2.26.jar";
      sha512 = "1744a48a47aedcbf19a0a93f78473cf0221fc4782852dca7fc02685719174664b4f9d95d353fcfc16902ac3815594511ba6d9ab14391f9b7e25ec9b2e777927a";
      name = "MouseTweaks-fabric-mc1.21-2.26.jar";
    })
    # ranged_weapon_api-fabric-2.3.3+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/AqaIIO6D/versions/j6w0ptJx/ranged_weapon_api-fabric-2.3.3%2B1.21.1.jar";
      sha512 = "95cd21612acd5506ae023856dfe7f712e5ca444c605083212c278f74b518930e5c53ce18a657f95ba817ba1ddeaf530da9a3d41ef3bcb454a778d789f421f80b";
      name = "ranged_weapon_api-fabric-2.3.3+1.21.1.jar";
    })
    # athena-fabric-1.21-4.0.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/b1ZV3DIJ/versions/7PcGW9Vp/athena-fabric-1.21-4.0.2.jar";
      sha512 = "4e2c7d1c8601be50229c94ded45b700adeef2f89ac5e713792603f678228c9fd4595301a857b09a2a8737298701b553555d9ef80ee139a2a774f0516c572afdc";
      name = "athena-fabric-1.21-4.0.2.jar";
    })
    # smarterfarmers-1.21-2.2.4-fabric.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Bh6ZOMvp/versions/bsYbob1i/smarterfarmers-1.21-2.2.4-fabric.jar";
      sha512 = "b9b8bb07f010b00e58bdf431c0ef259598e9af54cab8dc9a45387816d457a7591244e6f6582e8f3e8137187f252f6238334010e04fc621e1a146a159b2ac8bd2";
      name = "smarterfarmers-1.21-2.2.4-fabric.jar";
    })
    # mineralchance-1.21.1-3.8.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/bu1hACOl/versions/Ek2V4pfu/mineralchance-1.21.1-3.8.jar";
      sha512 = "65e043d15bf8ff00f095e2109f87b99bb23a7ce092dc3fe9c418b7d8afce5d0e08db16c5d7a51985fe5c92934816bc35ad9fd769394c5914f6123700a0cd9cc4";
      name = "mineralchance-1.21.1-3.8.jar";
    })
    # entity_texture_features_1.21-fabric-7.0.8.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/BVzZfTc1/versions/P3oS1dIC/entity_texture_features_1.21-fabric-7.0.8.jar";
      sha512 = "180f3d27ec18026fa27b1f49eb6bcec46c62b29c744ab81182e1c0834363472d2978c4a96074e678635a442019e0645ef6930feb0e03edc9fc289305f855f14c";
      name = "entity_texture_features_1.21-fabric-7.0.8.jar";
    })
    # midnightcontrols-fabric-1.10.0.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/bXX9h73M/versions/mZMBB8jx/midnightcontrols-fabric-1.10.0.1.jar";
      sha512 = "777dca100c9f55c9352eb3e1ab962518ab991632d0a0126844ccef07afa3d6a3a7c91748a0f71468574739dce349893e951730b0e658572c89a3830cb275621a";
      name = "midnightcontrols-fabric-1.10.0.1.jar";
    })
    # midnightlib-fabric-1.9.2+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/codAaoxh/versions/3tCMjbnf/midnightlib-fabric-1.9.2%2B1.21.1.jar";
      sha512 = "6ec997857e395c2b6081e4e117995e3b58ff3aff8353f51867d241db1b8f45c2d9985647301cb1946ddd85bf783362030b83ec1f61ec5c74e18ea5b48f1fd683";
      name = "midnightlib-fabric-1.9.2+1.21.1.jar";
    })
    # YungsCaveBiomes-1.21.1-Fabric-3.1.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/cs7iGVq1/versions/geZa9lJS/YungsCaveBiomes-1.21.1-Fabric-3.1.1.jar";
      sha512 = "b7fd6386b6652366a950375d352f011310fb40c14aef668d9cf1a4f63080ae3d6b46db302117a32359fbff3327b23b7275f0e39b487e9261f2e5b66a3dbe0409";
      name = "YungsCaveBiomes-1.21.1-Fabric-3.1.1.jar";
    })
    # Highlighter-1.21-fabric-1.1.11.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/cVNW5lr6/versions/Pg76zkO0/Highlighter-1.21-fabric-1.1.11.jar";
      sha512 = "4cc5dbb941957b2045199839b43688b6018143a5c105b883d02952addda379039a0aaa203cd29364d8e89b4db6dc68f876ef759d303e3186860b1785497cd4fc";
      name = "Highlighter-1.21-fabric-1.1.11.jar";
    })
    # YungsBetterCaves-1.21.1-Fabric-3.1.4.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Dfu00ggU/versions/72UkhXm7/YungsBetterCaves-1.21.1-Fabric-3.1.4.jar";
      sha512 = "347306c83e1d4f8381e2db410b4ee03e4d2b0f13846fefe33bead3fc85ff78a372e477a930c7251bb44f8d6d7841ce7719239562b6e8f6fcd3298741363f6cae";
      name = "YungsBetterCaves-1.21.1-Fabric-3.1.4.jar";
    })
    # dragondropselytra-1.21.1-3.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/DPkbo3dg/versions/PULGUIYZ/dragondropselytra-1.21.1-3.5.jar";
      sha512 = "db0c09f36a818d6c1b259332c4f66ff5956c16c85ba3ca6dea6d84e4ba88da5abe10803aba60489a2e08a7a7df38e7bf9b413b8358db2fec6cb0bdf7e23602c2";
      name = "dragondropselytra-1.21.1-3.5.jar";
    })
    # silkiertouch-1.21.1-1.0.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/dUaXeoyM/versions/TngkMccX/silkiertouch-1.21.1-1.0.jar";
      sha512 = "7aacad10ee0ea27d6c38c3c2feeb09393ae1317804da6d24ecaa0b3a6fdec019a44762c922c0c2adf54fc2cfe8a5b71825955662592195969752bbabf650153b";
      name = "silkiertouch-1.21.1-1.0.jar";
    })
    # SereneSeasons-fabric-1.21.1-10.1.0.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/e0bNACJD/versions/UqA7miTT/SereneSeasons-fabric-1.21.1-10.1.0.1.jar";
      sha512 = "b60eaacd452ea1a99198a8562f5bc4a10c42ae18853cdccb79fd4d33da784cbad7fa354a431fe33e157b82523ed4bcdd14e1c4b03f9f49ccac2e794b4223e73c";
      name = "SereneSeasons-fabric-1.21.1-10.1.0.1.jar";
    })
    # collective-1.21.1-8.13.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/e0M1UDsY/versions/VTg6femX/collective-1.21.1-8.13.jar";
      sha512 = "20ade6d666440659d38ec43202624993f47681a844c7f9e3e66a462e9f88f5d98bdd9a0a26278b1ed94bd4836b3c9cdbcfef73ad8515555f239e84bfea45d938";
      name = "collective-1.21.1-8.13.jar";
    })
    # nohostilesaroundcampfire-1.21.1-7.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/EJqeyaVz/versions/FH8UmhVY/nohostilesaroundcampfire-1.21.1-7.2.jar";
      sha512 = "9bb3f1290dd13537f8cacab679626645302ac3ee68d8d9701d6fda99dc33e95dd0ba2dd5cc482ddb76f4a4ee6fe859a5ce2b805ce8b17b4c58229732c71e30ca";
      name = "nohostilesaroundcampfire-1.21.1-7.2.jar";
    })
    # dungeon_difficulty-fabric-3.6.10+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/ENZmbSFZ/versions/txjyPgdx/dungeon_difficulty-fabric-3.6.10%2B1.21.1.jar";
      sha512 = "ce2d213ee7289e1733c3c3616d6f8b7789ea653bc2092d3cb4a026c7d9974040f89e20a9790b60ae711910e237df452d709fc97250df8573c4836e67924a2f09";
      name = "dungeon_difficulty-fabric-3.6.10+1.21.1.jar";
    })
    # appleskin-fabric-mc1.21-3.0.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/EsAfCjCV/versions/b5ZiCjAr/appleskin-fabric-mc1.21-3.0.6.jar";
      sha512 = "accbb36b863bdeaaeb001f7552534f3bdf0f27556795cf8e813f9b32e7732450ec5133da5e0ec9b92dc22588c48ffb61577c375f596dc351f15c15ce6a6f4228";
      name = "appleskin-fabric-mc1.21-3.0.6.jar";
    })
    # tntbreaksbedrock-1.21.1-3.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/eU2O6Xp1/versions/g3JXlbSH/tntbreaksbedrock-1.21.1-3.5.jar";
      sha512 = "c39b8ed9ce38ad7b2a48a0e522ef752683483ac28c1f8093346b4343462b2886e21948dea46a0c311d9748f78ab4a002f617ac59db60510dd7bbeee0aaa412ae";
      name = "tntbreaksbedrock-1.21.1-3.5.jar";
    })
    # replantingcrops-1.21.1-5.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/EXzIPtJo/versions/dJ9RP7Em/replantingcrops-1.21.1-5.5.jar";
      sha512 = "6fb07e8dca7eb51982c7abd0a0f6d60af81d267064b7a16197a0f484bee801837126dd080932ffb7cd421b9968d54fb71c36481ec513e8b127005820f653ed5b";
      name = "replantingcrops-1.21.1-5.5.jar";
    })
    # AmbientSounds_FABRIC_v6.3.1_mc1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/fM515JnW/versions/ybXRUW4r/AmbientSounds_FABRIC_v6.3.1_mc1.21.1.jar";
      sha512 = "11cc959f768506329c8938e95f4a0086c4a00cff82852e09c72f60d0938a91beba53499ec4c1cf11abc07f8b853bcb4ff8f87268b67b274fc6972f9abf9a0b92";
      name = "AmbientSounds_FABRIC_v6.3.1_mc1.21.1.jar";
    })
    # NaturesCompass-1.21.1-2.2.7-fabric.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/fPetb5Kh/versions/9W2MUsnU/NaturesCompass-1.21.1-2.2.7-fabric.jar";
      sha512 = "95e686f2b4d13c8d2e00ce24ef32075900aaacf38b2b6af676e92ef8936ea39b95146fea05321029a73a3322ba685361afbe7bbe6667143bf27fead0c5d54f8c";
      name = "NaturesCompass-1.21.1-2.2.7-fabric.jar";
    })
    # krypton-0.2.8.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/fQEb0iXm/versions/Acz3ttTp/krypton-0.2.8.jar";
      sha512 = "5f8cf96c79bfd4d893f1d70da582e62026bed36af49a7fa7b1e00fb6efb28d9ad6a1eec147020496b4fe38693d33fe6bfcd1eebbd93475612ee44290c2483784";
      name = "krypton-0.2.8.jar";
    })
    # paladins-fabric-2.6.4+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/FxXkHaLe/versions/uzAvtQmY/paladins-fabric-2.6.4%2B1.21.1.jar";
      sha512 = "66ade7a1e03272168a918479a529e13f562dd1f1ea1a13f5fd796df4028e7c5b83508953ae66e4804d3cab7bd9a5a6ae0ed77c5f3b7ca90aca8b4ad149db4253";
      name = "paladins-fabric-2.6.4+1.21.1.jar";
    })
    # smallernetherportals-1.21.1-3.9.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/fYAofsi6/versions/ZAbiGvCu/smallernetherportals-1.21.1-3.9.jar";
      sha512 = "94f75829c7ef07b28280240052be4fe3411eaee6c6fd70f98958b478fb3f04d3bf8646f63f57470a3ea21c42ff1871053d8d8107219fa51965d798688b3335a4";
      name = "smallernetherportals-1.21.1-3.9.jar";
    })
    # better-end-21.0.11.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/gc8OEnCC/versions/4qhBEg6J/better-end-21.0.11.jar";
      sha512 = "d3094b88202fca1ccc055e8429eac42eac1bd696a82ed650a9f1426cd5b28bd08e0af4d41664ed3fad10d8477c6da7c6be9d626a5664cfbc664844355c97c5b1";
      name = "better-end-21.0.11.jar";
    })
    # respawningshulkers-1.21.1-4.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/gHCmhGUV/versions/zkxWsh1p/respawningshulkers-1.21.1-4.1.jar";
      sha512 = "494bf284e776ac2130ba5e5756714fb99549751b38bc290b95eba2c0770da9e28c1a8a1bfd608b348764a1efacbbe8f9d129ef3e0e4e727fc0542ed0c5d18842";
      name = "respawningshulkers-1.21.1-4.1.jar";
    })
    # Almanac-1.21.1-2-fabric-1.5.0.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Gi02250Z/versions/PntWxGkY/Almanac-1.21.1-2-fabric-1.5.0.jar";
      sha512 = "b2c8f89c615cd1279977b479dcc1aedc273f941c9d1eec91b6af97d57629e03d9213fade87755922bb19456ed72d2a033e08323a388a2e607cb0cb6612ee68ef";
      name = "Almanac-1.21.1-2-fabric-1.5.0.jar";
    })
    # ghosts-fabric-1.21.1-1.2.0.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/gJKLGvbS/versions/NpL5z5fE/ghosts-fabric-1.21.1-1.2.0.jar";
      sha512 = "312b9315ee1d32d4bbe0bc74df0c516ea304d4d9181f9fa9b2045ff5868e7f9ea5f2bc55bb55f98a73a1c4bbc80e3577efe2ba80732f8c3bc9964f3a8bde0d77";
      name = "ghosts-fabric-1.21.1-1.2.0.jar";
    })
    # cullleaves-fabric-4.1.1+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/GNxdLCoP/versions/b3VxU7eO/cullleaves-fabric-4.1.1%2B1.21.1.jar";
      sha512 = "43389205cfdc35da3fb07ab22284a0a158e8b80dda888be5b3b742280670a55ee0df79cc45f23081d8b378a287c08109b51d220ef01dd6e4f239e7939e542ce8";
      name = "cullleaves-fabric-4.1.1+1.21.1.jar";
    })
    # villagernames-1.21.1-8.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/gqRXDo8B/versions/MTjxRIUz/villagernames-1.21.1-8.2.jar";
      sha512 = "8344c93a58fd5ffcecaf26516af7c91e357c7842bf43e4f66096bbe4b31129ca0fd1795562349a8cc91bf5eb15ca3bd76151cf12c9ad57cdde257807a4cd9921";
      name = "villagernames-1.21.1-8.2.jar";
    })
    # lithium-fabric-0.15.1+mc1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/E5eJVp4O/lithium-fabric-0.15.1%2Bmc1.21.1.jar";
      sha512 = "bb0d13b429c3f790b3f8d42312a104eb7f33dadc0b1eb3b037255af2d1b17a3c51db7d9a4cf8552f9410922f03ab030e124cb5c0661d2442e63bef8a1d133136";
      name = "lithium-fabric-0.15.1+mc1.21.1.jar";
    })
    # dismountentity-1.21.1-3.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/H7N61Wcl/versions/PVx8sPK6/dismountentity-1.21.1-3.6.jar";
      sha512 = "390c03a2ce2644abfa95645b9395cd472ae32ead35f206ce763b32ab21691f9fb090ab8c3edc4a522ebbdbb450b27b8987e658ac8b76d464f8a687529467cc98";
      name = "dismountentity-1.21.1-3.6.jar";
    })
    # lovely_snails-1.2.0+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/hBVVhStr/versions/5MD6c3zD/lovely_snails-1.2.0%2B1.21.1.jar";
      sha512 = "50a71bc00f58b5329a7e3cf719a89da7421bba1201bba39e330d7f20340f2346d17522019a50892799e04b37a387b8431ec8890b46ffcaf926c923c1323baeb3";
      name = "lovely_snails-1.2.0+1.21.1.jar";
    })
    # YungsMenuTweaks-1.21.1-Fabric-2.1.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Hcy2DFKF/versions/ROfVrQnL/YungsMenuTweaks-1.21.1-Fabric-2.1.2.jar";
      sha512 = "c05bfbd328d4f152b87be212fc7f0c9c6aba92de93eb6c410424875d31764e15bc803d6b6b7ff13b45235a3162574d6f6aa95c451aab1038d706964fc70e18e2";
      name = "YungsMenuTweaks-1.21.1-Fabric-2.1.2.jar";
    })
    # gravestones-1.2.7+1.21+A.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Heh3BbSv/versions/HO3Zv8HU/gravestones-1.2.7%2B1.21%2BA.jar";
      sha512 = "537e4acbc9cb35936c78703982ab74aac7a30e7c13214ce9b69c5cefd37813a5dcdaf635b496ab4ca740f7bd709157cc83db0ce2c9d0412588fa494b23d529cc";
      name = "gravestones-1.2.7+1.21+A.jar";
    })
    # YungsBetterMineshafts-1.21.1-Fabric-5.1.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/HjmxVlSr/versions/4ybDuGhA/YungsBetterMineshafts-1.21.1-Fabric-5.1.1.jar";
      sha512 = "f19c53ecac52866f65e1791f7b46ecc68fff6b1912ac47b42bf64097012262691c7184ea4a95db5e7bfcfda6c9532138dfe29e29af4ab108a407807a8db28074";
      name = "YungsBetterMineshafts-1.21.1-Fabric-5.1.1.jar";
    })
    # YungsBridges-1.21.1-Fabric-5.1.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Ht4BfYp6/versions/8h9N9fvs/YungsBridges-1.21.1-Fabric-5.1.1.jar";
      sha512 = "435c18442ca94c3b44a6972dddca7ca0f2437427627340b1c5aab7ac41001c9d9e5225de34b493acb0fec57f0fc1fe93818e0dc05d76bb059c6608e0155efb2f";
      name = "YungsBridges-1.21.1-Fabric-5.1.1.jar";
    })
    # BiomesOPlenty-fabric-1.21.1-21.1.0.13.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/HXF82T3G/versions/YPm4arUa/BiomesOPlenty-fabric-1.21.1-21.1.0.13.jar";
      sha512 = "34bf011c38be11d593b1e71a2a398431468c42d5a1744f0572158cd025670f8e9171bbf93baaf442708f2d0171f0e158592d4f48184998e0bff4c9836460e240";
      name = "BiomesOPlenty-fabric-1.21.1-21.1.0.13.jar";
    })
    # passiveshield-1.21.1-3.7.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/iQBrasyH/versions/qCIUvQPR/passiveshield-1.21.1-3.7.jar";
      sha512 = "91e142851d14fe35b80fb6ba16e06076241cbef87a1fb74e2c02f6a4bd7d1eb0f5a905da5852f79f52768f72aebee6aafe6453d024c4601d2ef7b8cfab28d1d8";
      name = "passiveshield-1.21.1-3.7.jar";
    })
    # doubledoors-1.21.1-7.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/JrvR9OHr/versions/KgGapm4H/doubledoors-1.21.1-7.2.jar";
      sha512 = "c88215ccbd8fd491ab334d60dbcc00f22664f01f95b638b679307c1b3857340ddb8041b7887be18a2cce128baae7685b8d097f840796894bd3ae8eac979ced66";
      name = "doubledoors-1.21.1-7.2.jar";
    })
    # TravelersTitles-1.21.1-Fabric-5.1.3.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/JtifUr64/versions/S27dNesu/TravelersTitles-1.21.1-Fabric-5.1.3.jar";
      sha512 = "120cf52c6f6dfbbcd29fa9bb8bf3c133d239c8e8da2332764a0c10081767b270df53c233c672b6092f8305998fe8b1a5b7b0f5b7c0621fc43321b54ee95e8316";
      name = "TravelersTitles-1.21.1-Fabric-5.1.3.jar";
    })
    # YungsBetterStrongholds-1.21.1-Fabric-5.1.3.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/kidLKymU/versions/uYZShp1p/YungsBetterStrongholds-1.21.1-Fabric-5.1.3.jar";
      sha512 = "01e467a5237a338d8347b79d2e99659a362b777c4ac10bf6e75382be072b645277b58c655b9b4ad69956f9836601c3a52c733ad437d1f6bd53ea13976545edaa";
      name = "YungsBetterStrongholds-1.21.1-Fabric-5.1.3.jar";
    })
    # fabric-seasons-2.4.2-BETA+1.21.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/KJe6y9Eu/versions/2mIvRTNp/fabric-seasons-2.4.2-BETA%2B1.21.jar";
      sha512 = "1fa611aecdeb7d3a7dbf46b29b3fcb747f02d8c3ebd58ffa47ecb6b07c049990b54843c207db4814ae1ab6b3ccfa2854864d245bdc3074fe52faa9097c3619d3";
      name = "fabric-seasons-2.4.2-BETA+1.21.jar";
    })
    # TerraBlender-fabric-1.21.1-4.1.0.8.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/kkmrDlKT/versions/XNtIBXyQ/TerraBlender-fabric-1.21.1-4.1.0.8.jar";
      sha512 = "f933f0c70babe3cf1efe3b8121486f26db9d48799b6d50557ec4f7bc47e553fe00c837f4940d70aa2eab7f13f91065a9e56c0cc53f8aa2393edaf423f80997b8";
      name = "TerraBlender-fabric-1.21.1-4.1.0.8.jar";
    })
    # healingcampfire-1.21.1-6.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/kOuPUitF/versions/Dq3x3ElV/healingcampfire-1.21.1-6.2.jar";
      sha512 = "157d0a34b13f594297ec7d587e6ed9097e24c6c21d143990a899cda0989902580518ba98181beb55f539a7a0c8feaf94e2b6230a9aee2619d3e5ec4798ec2d3d";
      name = "healingcampfire-1.21.1-6.2.jar";
    })
    # conduitspreventdrowned-1.21.1-3.9.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/kpKchl4x/versions/oHxzVjRs/conduitspreventdrowned-1.21.1-3.9.jar";
      sha512 = "f12321f1df32fd7dcb771c46c263d9fe1415588652a460d20e583e1e26d0775875849eb298541c4e7bb4d4ad775aea5590bdab750b5933b6f5e7c5e93536985b";
      name = "conduitspreventdrowned-1.21.1-3.9.jar";
    })
    # waveycapes-fabric-1.8.2-mc1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/kYuIpRLv/versions/ZtvlEp9r/waveycapes-fabric-1.8.2-mc1.21.1.jar";
      sha512 = "916cc3191b7338e89901871bfcff8c7e58d9e8deacf67ec807a3de26a8d0cbad4fbaa6c88b4c89853b8b85f37059374c038946e7d4b822976b235ba378b444fa";
      name = "waveycapes-fabric-1.8.2-mc1.21.1.jar";
    })
    # fastercrouching-1.21.1-2.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/lgEczyrc/versions/cFLoIUAY/fastercrouching-1.21.1-2.6.jar";
      sha512 = "0fed5c38b898900cdda4f1dc18c1d5ebff0313bd4130c2c25fa6adecd779b835e43d7a5bce29f73dfe6ab02a340d4f71ea2a465c53757b05ccd275e3e3eba42d";
      name = "fastercrouching-1.21.1-2.6.jar";
    })
    # waystones-fabric-1.21.1-21.1.25.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/LOpKHB2A/versions/VdAnzzFj/waystones-fabric-1.21.1-21.1.25.jar";
      sha512 = "2cd6a49d1d080e9912991d2cfccd19c0c4cbcd92d9c81fb3cc166f79ca9b9d654329088e40427c905215aea9ef5b3c735cf51ef5e49a00ae0253c91ff76c28c8";
      name = "waystones-fabric-1.21.1-21.1.25.jar";
    })
    # runes-fabric-1.2.1+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/lP9Yrr1E/versions/j1ymRQwT/runes-fabric-1.2.1%2B1.21.1.jar";
      sha512 = "e09f7809280b0a07f294d732b7b4fee917b6cf1bf5df25aebc274e60b46a7ee376f203c0f0fb22717d95b5047f3619cae4ee15ed147af7b548d41743b1e28b82";
      name = "runes-fabric-1.2.1+1.21.1.jar";
    })
    # dynamic-fps-3.9.5+minecraft-1.21.0-fabric.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/LQ3K71Q1/versions/td4DfKSI/dynamic-fps-3.9.5%2Bminecraft-1.21.0-fabric.jar";
      sha512 = "2be64fb726088e20edfda8f07f7ad4eac06e787487ea54dc8485e753c664d8ef12f8fc0a6d3244e0a699300ff2ac4c84d85b8aa5fd4d58a87a8fdec74b42a6f3";
      name = "dynamic-fps-3.9.5+minecraft-1.21.0-fabric.jar";
    })
    # nametagtweaks-1.21.1-4.0.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/LrLZEnPl/versions/5Qka8LfN/nametagtweaks-1.21.1-4.0.jar";
      sha512 = "de74cd8c264f9f5a4b18fa45486459891ca2976907e00627b1dd72b5ded61c97c5b7715f0b880c2c622cc9ca28d75be8af29aeee812001eaa93a395918deda49";
      name = "nametagtweaks-1.21.1-4.0.jar";
    })
    # structure_pool_api-fabric-1.2.1+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/LrYZi08Q/versions/Y6aBoKEl/structure_pool_api-fabric-1.2.1%2B1.21.1.jar";
      sha512 = "5db479ad64411a36ab8a4be746625cbd67189a9fb56a5853a9715159afe6cd1f8db5216018330f395211b491ae3cba1da80aa1a66f5904aa17bf18518f71fd3e";
      name = "structure_pool_api-fabric-1.2.1+1.21.1.jar";
    })
    # balm-fabric-1.21.1-21.0.55.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/MBAkmtvl/versions/jiTpUYmp/balm-fabric-1.21.1-21.0.55.jar";
      sha512 = "616c8c0ca06920516a07dbd3afa4c46ba243866de375d9aa5140be803284bfe2c434e93d838462776d71c6afea98766fc6b27cd00a6880e49170478448f7415b";
      name = "balm-fabric-1.21.1-21.0.55.jar";
    })
    # zombieawareness-fabric-1.21.0-1.13.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/mMTOWOaA/versions/lBdgO4GL/zombieawareness-fabric-1.21.0-1.13.2.jar";
      sha512 = "fd1492fc73ebccdbb87668e09014db4b94033003ec56c31f7bbb8a0a223200069970c0711c8f8a1b9ba5eb3683192a208e8de4728974498a7aef66f540f5a49d";
      name = "zombieawareness-fabric-1.21.0-1.13.2.jar";
    })
    # modmenu-11.0.3.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/mOgUt4GM/versions/YIfqIJ8q/modmenu-11.0.3.jar";
      sha512 = "4c6387a059c7ac9028acc3d78124af02a4495bef2c16783bbffe5bf449067daf2620708fd57f8725e46f0c34d0f571adf60f0869742bfe7f6101ddf13a2a87da";
      name = "modmenu-11.0.3.jar";
    })
    # notenoughanimations-fabric-1.11.1-mc1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/MPCX6s5C/versions/MK7dm8OP/notenoughanimations-fabric-1.11.1-mc1.21.1.jar";
      sha512 = "d522dbbc08e098c231bb46e0a92cfc91750f0204a539f6a6f91ec5c5422e514bafcd06565ff7bd4c864594b884a169d7cb7c03ecd65af53fb550235e64065111";
      name = "notenoughanimations-fabric-1.11.1-mc1.21.1.jar";
    })
    # stackrefill-1.21.1-4.9.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/mQWkB9ON/versions/5RkgQCwL/stackrefill-1.21.1-4.9.jar";
      sha512 = "42f5bf809f533d472ff64d2b7b55f557b2ce921674469291dc34db4717cd88fc1114703ad420e1d758edf077907f4ff60a404610e24524f2cd2bce49fe2a7b74";
      name = "stackrefill-1.21.1-4.9.jar";
    })
    # elytraslot-fabric-9.0.1+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/mSQF1NpT/versions/jxx2pc4h/elytraslot-fabric-9.0.1%2B1.21.1.jar";
      sha512 = "fab675a85858199c268ec1f09bac59ef53d0eee8703c3325619ba1dc9559cbff21d274a7fcbd1046edf17aa30121c99d22a2514f714a7623e23331b985132659";
      name = "elytraslot-fabric-9.0.1+1.21.1.jar";
    })
    # XaerosWorldMap_1.39.12_Fabric_1.21.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/NcUtCpym/versions/HXRzzOuL/XaerosWorldMap_1.39.12_Fabric_1.21.jar";
      sha512 = "e1143acbe724d1b014c4a314ac8f56ca9d2f8892a33cdf0c18f9b0337f347b60bd4463a8af0e5aafd3f384c58e0078b4c7d1df3feed20a6c74656d44a6e4452f";
      name = "XaerosWorldMap_1.39.12_Fabric_1.21.jar";
    })
    # wizards-fabric-2.6.5+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/NkGaQMDA/versions/dgQ9h3nd/wizards-fabric-2.6.5%2B1.21.1.jar";
      sha512 = "26ae765cd3237383ed27642e648bd426ca2eb1759b36ca41dffad2c4ff407f1a280348991a98a403537d3fe61fa768623da26728dbf4dc4a7962f38d113e8c99";
      name = "wizards-fabric-2.6.5+1.21.1.jar";
    })
    # modernfix-fabric-5.25.1+mc1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/nmDcB62a/versions/NnNX8LBn/modernfix-fabric-5.25.1%2Bmc1.21.1.jar";
      sha512 = "dc67d6e023e1fcdeaf7837917c477cba212c611dfc2463c6ea021319c644087c79b477e0ea8194e113ddd7332fd5c6d82baa47c291eaac7f4a86252507b4e19f";
      name = "modernfix-fabric-5.25.1+mc1.21.1.jar";
    })
    # entityculling-fabric-1.9.5-mc1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/NNAgCjsB/versions/xcyXBGgI/entityculling-fabric-1.9.5-mc1.21.1.jar";
      sha512 = "2a980756192abb8f7841e61017d77b16824752d349348976ba890779a8f556b4a0edb7b392bc5a29b29975342b6b18d8cfde888ae670532ce2418e5943f2009c";
      name = "entityculling-fabric-1.9.5-mc1.21.1.jar";
    })
    # spidersproducewebs-1.21.1-3.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/NoznOJXq/versions/cYCy5NTm/spidersproducewebs-1.21.1-3.6.jar";
      sha512 = "dcbf236861621a15e89652f74e96e885a5b30e09c0c86c0d44c3394c47fab6f7acb81faaebd76726199522a65710e62fb1166c30c18075e4e6c3db78aecf9499";
      name = "spidersproducewebs-1.21.1-3.6.jar";
    })
    # areas-1.21.1-6.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/NWvsqJ2Z/versions/Ppbb7pia/areas-1.21.1-6.1.jar";
      sha512 = "0eb79d3ff53ff35e8e5a45ea1b449239cbb3783149d70159d05d4b2d6d835c04c437cbc4c21d0679009cf9f97277de5cd03f2f71f6c53f537a6e2e72eec3831e";
      name = "areas-1.21.1-6.1.jar";
    })
    # YungsBetterDungeons-1.21.1-Fabric-5.1.4.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/o1C1Dkj5/versions/fQ7EjDPE/YungsBetterDungeons-1.21.1-Fabric-5.1.4.jar";
      sha512 = "4a11b1b1f845ddd1709e6a6cad6c6d5043704afbd4b97cb2afcd316f8fdcf6e398f8dd55480d02e32326ac5b49b6b273ec99cd2b1e311bed24f786e6d176612c";
      name = "YungsBetterDungeons-1.21.1-Fabric-5.1.4.jar";
    })
    # InventoryProfilesNext-fabric-1.21.1-2.2.3.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/O7RBXm3n/versions/A2gB9UGG/InventoryProfilesNext-fabric-1.21.1-2.2.3.jar";
      sha512 = "6a57d78a1ee92f35e41b928070b3ebcc91701183fd2040996146e71eec9d39c055fcb13a070f5e0870427b9b5fbdd423e711f1fd80dc24dd1b33670c4b3cbc46";
      name = "InventoryProfilesNext-fabric-1.21.1-2.2.3.jar";
    })
    # keepmysoiltilled-1.21.1-2.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/OC5Zubbe/versions/SR3aj6gK/keepmysoiltilled-1.21.1-2.5.jar";
      sha512 = "091649855568cdfb2fec2950fd537abc00844915e19e7afb58b0d712a71388676e81482c705105af4b97656653bc0a21e7df8b72ad68e244c0eadbd8b1731483";
      name = "keepmysoiltilled-1.21.1-2.5.jar";
    })
    # enhancedblockentities-0.10.2+1.21.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/OVuFYfre/versions/HBZAPs3u/enhancedblockentities-0.10.2%2B1.21.jar";
      sha512 = "60e01db603fcf1392c0cd5c3ce742e568f7d445d83fe60828b21f546e7d29fb6947231f22d28e29b07f4bdcb767b6dc2a2398b4decea665ecba1166690a44d49";
      name = "enhancedblockentities-0.10.2+1.21.jar";
    })
    # fabric-api-0.116.7+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/m6zu1K31/fabric-api-0.116.7%2B1.21.1.jar";
      sha512 = "0d7bf97e516cfdb742d7e37a456ed51f96c46eac060c0f2b80338089670b38aba2f7a9837e5e07a6bdcbf732e902014fb1202f6e18e00d6d2b560a84ddf9c024";
      name = "fabric-api-0.116.7+1.21.1.jar";
    })
    # handcrafted-fabric-1.21.1-4.0.3.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/pJmCFF0p/versions/f0pKpUWd/handcrafted-fabric-1.21.1-4.0.3.jar";
      sha512 = "6274aa51bec1076faf9eef9783c676ab2a12cd87eaf9beb72258c50bf0478d702d9ea6a21e8f1fa6e4ba5084698f0aa0f7edcfe631d64b683c23e4db884c187f";
      name = "handcrafted-fabric-1.21.1-4.0.3.jar";
    })
    # animatica-0.6.1+1.21.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/PRN43VSY/versions/LHBm6fEV/animatica-0.6.1%2B1.21.jar";
      sha512 = "d8cba8839c2ed329f32f63978e431a75b4e72e506282cf49d151a43302915524c50edbd29af2f5247f479d7456b074011bd768efbd0f4ece311c6e0e2ee0de3c";
      name = "animatica-0.6.1+1.21.jar";
    })
    # sodium-extra-fabric-0.6.0+mc1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/PtjYWJkn/versions/anDafurZ/sodium-extra-fabric-0.6.0%2Bmc1.21.1.jar";
      sha512 = "fa7fa78b5d4ef19eff4b3e711f5c79cb54e71c55c6af43fa6867c86e3e54be5045a681b809b8482227c5bda4da4afdce6f30b91e8021d3fae7e34be252b9c972";
      name = "sodium-extra-fabric-0.6.0+mc1.21.1.jar";
    })
    # archers-fabric-2.6.8+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/QgooUXAJ/versions/W9R5oGCJ/archers-fabric-2.6.8%2B1.21.1.jar";
      sha512 = "cec3fc94a6420d6623e4af421e123f6bbd8f11d1cb12c0306413436139c9ea625271de47c669925395a8c1c0607160c5c2aab41ec5c9aae870d957d8d8b890f6";
      name = "archers-fabric-2.6.8+1.21.1.jar";
    })
    # PresenceFootsteps-1.11.1+1.21.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/rcTfTZr3/versions/cCWAPoWg/PresenceFootsteps-1.11.1%2B1.21.jar";
      sha512 = "c6c8bfb47bc05cade66f3250e410021f63105709198755253c9be7aebcb381957b060ade129cf4801997c379608fb1056bc73f90080867c423f2f48152553d77";
      name = "PresenceFootsteps-1.11.1+1.21.jar";
    })
    # visuality-0.7.7+1.21.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/rI0hvYcd/versions/dhKbgdIb/visuality-0.7.7%2B1.21.jar";
      sha512 = "793f7164f9caf1b8e2b6b2f9f1327c40179b633217702bf79e16930cc5c548e44e6f0cac4628963fcc9e65cc9d63c4493678840242017c33be92a0e94c880f51";
      name = "visuality-0.7.7+1.21.jar";
    })
    # edibles-1.21.1-4.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Rjl8pCZ9/versions/wkFj4frD/edibles-1.21.1-4.5.jar";
      sha512 = "0f38a186771f559bfdb9a0d221656ef806c03d1f996dd7691ea91fe4199901c680a549dc8779b95dfd785315e8d87cb31192c82a5f35fd7be63dde1af9a582ff";
      name = "edibles-1.21.1-4.5.jar";
    })
    # coroutil-fabric-1.21.1-1.3.8.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/rLLJ1OZM/versions/U0NUocji/coroutil-fabric-1.21.1-1.3.8.jar";
      sha512 = "8fe6c7bc6ddf5e5b29fb0975bb8ba56f9c24330ddf1ce7d82b43400181a5a7ad24cde40e69b9b509d36c11839d37b360cfe531996e751cdd4f1e740cd67991b1";
      name = "coroutil-fabric-1.21.1-1.3.8.jar";
    })
    # travelersbackpack-fabric-1.21.1-10.1.29.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/rlloIFEV/versions/NykLNihR/travelersbackpack-fabric-1.21.1-10.1.29.jar";
      sha512 = "4cddb134ed76078ed54e75b5ada94249916c01d3f45b93967bd0e1d15dc8fa9a0623e795251ac3f7633482ef2c96fa82cd83a41aaff5181c5527568ee3b03e1d";
      name = "travelersbackpack-fabric-1.21.1-10.1.29.jar";
    })
    # eating-animation-1.21+1.9.72.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/rUgZvGzi/versions/KWZCioh0/eating-animation-1.21%2B1.9.72.jar";
      sha512 = "6513938ddbbbf32602982b50296c0261ce5f1bc33838675bc4574b0ec710bc9a5622f838ab5adbdc5b9c01f7e2696443c3bc377f1cc1f1b8376539004e5a871c";
      name = "eating-animation-1.21+1.9.72.jar";
    })
    # GlitchCore-fabric-1.21.1-2.1.0.0.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/s3dmwKy5/versions/lbSHOhee/GlitchCore-fabric-1.21.1-2.1.0.0.jar";
      sha512 = "ccd5c3812faf1161f61a894deec609eb6c3de36debe63dc00b75698a9b71dfb30bc00e0a34c3e030b3adb4c224e829783f66ad66768c28dedbefc024ddbd6041";
      name = "GlitchCore-fabric-1.21.1-2.1.0.0.jar";
    })
    # nightlights-fabric-1.3.0.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/s7pMb898/versions/owmHxuVw/nightlights-fabric-1.3.0.jar";
      sha512 = "6957ccf58bb6c7d851af90c08f9a6ac044b32d7bfeecd5b47259d2966c93968024af57ee0a7a6019ddbe802c3a896e6bc6cc4b24c5a5e521373586310d82fdf5";
      name = "nightlights-fabric-1.3.0.jar";
    })
    # undergroundbeacons-1.21.1-1.0.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/SMC0xf5E/versions/LHTttXOg/undergroundbeacons-1.21.1-1.0.jar";
      sha512 = "89741776b22f597422bc5a2a0900dba3f1047a13e82ac667cbd41a683c5f4f86c8fda8c84b5ce0285f55a3300adddecffce2fd52470dc9c52926ddc01889a704";
      name = "undergroundbeacons-1.21.1-1.0.jar";
    })
    # jewelry-fabric-2.3.2+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/sNJAIjUm/versions/93Bti7MQ/jewelry-fabric-2.3.2%2B1.21.1.jar";
      sha512 = "50a1f286437cded532ddc3caea0e6ac8ae855c46fd454df9463405f01734c71450f8194f211678cef3725ad3693f47064736b07c2fe1702816ab2ed0257b9a52";
      name = "jewelry-fabric-2.3.2+1.21.1.jar";
    })
    # YungsBetterWitchHuts-1.21.1-Fabric-4.1.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/t5FRdP87/versions/bdpPtvTn/YungsBetterWitchHuts-1.21.1-Fabric-4.1.1.jar";
      sha512 = "ca6749bd01cd5b623d6f58561a57c2e2a8f769c31e3947fceac22e495f5da5b803d05777c6e3e122da40c4dd49444d58aaface0220b0a3106a5b5e27658b2d9f";
      name = "YungsBetterWitchHuts-1.21.1-Fabric-4.1.1.jar";
    })
    # fabric-carpet-1.21-1.4.147+v240613.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/TQTTVgYE/versions/f2mvlGrg/fabric-carpet-1.21-1.4.147%2Bv240613.jar";
      sha512 = "e6f33d13406796a34e7598d997113f25f7bea3e55f9d334b73842adda52b2c5d0a86b7b12ac812d7e758861e3f468bf201c6c710c40162bb79d6818938204151";
      name = "fabric-carpet-1.21-1.4.147+v240613.jar";
    })
    # infinitetrading-1.21.1-4.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/U3eoZT3o/versions/QV78XqMj/infinitetrading-1.21.1-4.6.jar";
      sha512 = "481b5ff880cc5b8adbda34f6e082c9df51956b0d2d2418703bd21257d71ad914b4f696edeeeaeec960fff475c0b2108923b3bb532abee665c4b5a075a1e26363";
      name = "infinitetrading-1.21.1-4.6.jar";
    })
    # jei-1.21.1-fabric-19.27.0.336.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/u6dRKJwZ/versions/VO5u0wi4/jei-1.21.1-fabric-19.27.0.336.jar";
      sha512 = "03a00bc1a7c45955ec0ef2f35b379a0c1322434b75a5d467d417d47fd1cbbaeec20f161541d0133d4fd1011a7f7e1279c158de30e9f183135a5d516750707fa3";
      name = "jei-1.21.1-fabric-19.27.0.336.jar";
    })
    # YungsApi-1.21.1-Fabric-5.1.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Ua7DFN59/versions/9aZPNrZC/YungsApi-1.21.1-Fabric-5.1.6.jar";
      sha512 = "fc05fb3941851cfa5c8e89f98704938a5b0581f66fe3b1b0d83b2f46f1cb903e1e1070f40c92a82da91813b36452358d6b2df7dc42a275f459dc5030ea467cb6";
      name = "YungsApi-1.21.1-Fabric-5.1.6.jar";
    })
    # shulkerdropstwo-1.21.1-3.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/UjXIyw47/versions/jBF1zfoq/shulkerdropstwo-1.21.1-3.5.jar";
      sha512 = "aa2e7678c27e7e49a51803a766620322a46d615929c7fe77d49bb34943e23c93dbe670fcc181a26e531c4d544c77c4303e5a0843af67049ee56f6f036eff473c";
      name = "shulkerdropstwo-1.21.1-3.5.jar";
    })
    # ferritecore-7.0.2-hotfix-fabric.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/uXXizFIs/versions/bwKMSBhn/ferritecore-7.0.2-hotfix-fabric.jar";
      sha512 = "ca975bd3708cd96d30cf1447ac8883572113562eb2dd697e60c1cf382d6b70d0b1a511fcbfd042c51b2cf5d5ffc718b847f845e4c8a3e421e8c9ee741119a421";
      name = "ferritecore-7.0.2-hotfix-fabric.jar";
    })
    # letmedespawn-1.21.x-fabric-1.5.0.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/vE2FN5qn/versions/Wb7jqi55/letmedespawn-1.21.x-fabric-1.5.0.jar";
      sha512 = "a1fc557b9985954258f30fa32d4134867d6cd1d045147171a89a711d63b1b94f5dd58564aa3060ce10e8d81c2be1d8bae7ff828ee9c24a1c1b9f8398564936a9";
      name = "letmedespawn-1.21.x-fabric-1.5.0.jar";
    })
    # c2me-fabric-mc1.21.1-0.3.0+alpha.0.362.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/VSNURh3q/versions/DSqOVCaF/c2me-fabric-mc1.21.1-0.3.0%2Balpha.0.362.jar";
      sha512 = "8653a751eb2ad1ad70da38017ccad0ee2bda5448ffe405d28049f09a61936765303f63ba4fcff798f32bb1e6b4645e892c275515b69c98c1730e24caab0ba7e0";
      name = "c2me-fabric-mc1.21.1-0.3.0+alpha.0.362.jar";
    })
    # combat_roll-fabric-2.0.6+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/wGKYL7st/versions/UkTSsgGt/combat_roll-fabric-2.0.6%2B1.21.1.jar";
      sha512 = "a39ce64716cd33ebe0ef7defd1765b8e512be8fbab10cff039d1abf9f264001fe790fd97a7c944e8ad31b26473db31b3946eec510e5dd6f8ec9c89c29db025a8";
      name = "combat_roll-fabric-2.0.6+1.21.1.jar";
    })
    # Clumps-fabric-1.21.1-19.0.0.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Wnxd13zP/versions/3ene3W1l/Clumps-fabric-1.21.1-19.0.0.1.jar";
      sha512 = "0aa8e3508d0a40ef814d4064c0b6cadba6326128dd878fe69f30677c889cec4ccb8f639c22bdd7083a73ae8fa76e1c115b5e4b1885904dc1244b02ab2f728e78";
      name = "Clumps-fabric-1.21.1-19.0.0.1.jar";
    })
    # gazebo-fabric-2.1.0+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/XIpMGI6r/versions/8dnK7blA/gazebo-fabric-2.1.0%2B1.21.1.jar";
      sha512 = "b92c48cfdc82e4987cef7aeaeae207c7e76083b9ca7186d45ec901d9904ce54ee8bbcbbf4c5c0ce788a3f4514e08da9541d586802af413ce4c054711c45126c6";
      name = "gazebo-fabric-2.1.0+1.21.1.jar";
    })
    # oreharvester-1.21.1-1.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Xiv4r347/versions/PZBcS2Yz/oreharvester-1.21.1-1.5.jar";
      sha512 = "65be29f010f58dbeea944c11d7ee8c4bb8176951f80f54421a5ff4cac7bf83d08696b87e6e7aa7814015129948886b67836b42ba30ad183a5be21e5f8de0c515";
      name = "oreharvester-1.21.1-1.5.jar";
    })
    # YungsBetterDesertTemples-1.21.1-Fabric-4.1.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/XNlO7sBv/versions/M6eeDRkC/YungsBetterDesertTemples-1.21.1-Fabric-4.1.5.jar";
      sha512 = "2bed532391cd1f2e5ed7986220f3b4c23d0c1302366b61baf1ca62a9620000bd58964cfd9a62fc52abbc95e76c1b3a4f85fbe88ca0a4006612f0493585c99084";
      name = "YungsBetterDesertTemples-1.21.1-Fabric-4.1.5.jar";
    })
    # spell_engine-fabric-1.8.19+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/XvoWJaA2/versions/dxnMs2Zt/spell_engine-fabric-1.8.19%2B1.21.1.jar";
      sha512 = "0580202ab5949a4c68310e9ca4b1f55df7990263c429edc55ae10a5633201e09556696f10f5f0e8650c92cd7d4b9f3bd77fcbf7a9ace2b8acdf80225cc6a9611";
      name = "spell_engine-fabric-1.8.19+1.21.1.jar";
    })
    # inventorymending-1.21.1-1.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/y6Ryy40D/versions/VeOSd0k4/inventorymending-1.21.1-1.2.jar";
      sha512 = "23a9fc9a48d0be75203a8f98f68439971bf5e984890956e7bbd9fc401e15ed77ae543b71f047ba8a182a6b0f29745eec5c27d5dd5cd6f6f682d92f67d57440ef";
      name = "inventorymending-1.21.1-1.2.jar";
    })
    # lambdynamiclights-4.8.7+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/yBW8D80W/versions/CQuTG9xY/lambdynamiclights-4.8.7%2B1.21.1.jar";
      sha512 = "eac2c2f5c0a5cc3fa28895ddc3203b2b7214c680dd9c47eabf308fa96f2f54d1a1a5a16b50c35865b61068bd834d538f90e02aceb4c5d9594793807b6068123c";
      name = "lambdynamiclights-4.8.7+1.21.1.jar";
    })
    # crittersandcompanions-fabric-1.21.1-2.3.4.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Yd4wb5wZ/versions/wHpQleS4/crittersandcompanions-fabric-1.21.1-2.3.4.jar";
      sha512 = "143848ee10a4494a7e1c027171e7fa7a624ae7aa5e6f881d6cc2504fb5a5466cb66ba09eedeeab073e8c5356cb333828c300a20eb7339e7877bc298118a0eb15";
      name = "crittersandcompanions-fabric-1.21.1-2.3.4.jar";
    })
    # justplayerheads-1.21.1-4.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/YdVBZMNR/versions/Bhim3m1a/justplayerheads-1.21.1-4.2.jar";
      sha512 = "951d13434f8b8b0a349aa07a8802f57722babc9aa6a348e119d7ae58a70236f82d3ef5e2d2dbf78a9a0cc12ad9430d98a15444bc37463a3ef06dd1a0911f1fc8";
      name = "justplayerheads-1.21.1-4.2.jar";
    })
    # iris-fabric-1.8.8+mc1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/YL57xq9U/versions/zsoi0dso/iris-fabric-1.8.8%2Bmc1.21.1.jar";
      sha512 = "2e6ba2ffa1e1a6799288245a7e0ac68ee8df1d41b98362189df58f535cae34fa9277801e4136633467341b7dae5be0e5c698011b480b3d91b66d3dd4f7567aa6";
      name = "iris-fabric-1.8.8+mc1.21.1.jar";
    })
    # inventorytotem-1.21.1-3.4.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/yQj7xqEM/versions/uCOQDBBn/inventorytotem-1.21.1-3.4.jar";
      sha512 = "5a5a7dc243d7d84da1ad7d8622ee22edc36204af731b92810f78cc7eaec16ffbb4dad85e15602fb69ad4611cc5ee3e95174e662c5fea662c8233e1319168e343";
      name = "inventorytotem-1.21.1-3.4.jar";
    })
    # YungsBetterNetherFortresses-1.21.1-Fabric-3.1.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Z2mXHnxP/versions/gxBGYcIL/YungsBetterNetherFortresses-1.21.1-Fabric-3.1.5.jar";
      sha512 = "74f9327ce3d17e78bef1945d6b241498f517e6e5ffae37c5c7a8acdc15b53bebf7447644517f76c4cecbf8a8530a888b6ee5035cf4f3b8e9441a2f665f7385d3";
      name = "YungsBetterNetherFortresses-1.21.1-Fabric-3.1.5.jar";
    })
    # YungsBetterJungleTemples-1.21.1-Fabric-3.1.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/z9Ve58Ih/versions/uiGCmR8O/YungsBetterJungleTemples-1.21.1-Fabric-3.1.2.jar";
      sha512 = "0b2912606607e4e85cd9b713c3d08986c4e7662da8964cad86d230ef13f57fd53adc7b7447145db95c6c3e9c85edb6c3a115a9f3126965855577792e29876e97";
      name = "YungsBetterJungleTemples-1.21.1-Fabric-3.1.2.jar";
    })
    # YungsExtras-1.21.1-Fabric-5.1.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/ZYgyPyfq/versions/aVsikHca/YungsExtras-1.21.1-Fabric-5.1.1.jar";
      sha512 = "a5b3281fc482167864745df34d80c834c42aa434f372ebb6ccb0cd84a8882ce344c247db5a8dea0300fe30ef39e2a85fa650216ff12adeb6c435e182e0ae2e55";
      name = "YungsExtras-1.21.1-Fabric-5.1.1.jar";
    })
    # moremobvariants-fabric+1.21-1.3.1.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/JiEhJ3WG/versions/7mUHEpdy/moremobvariants-fabric%2B1.21-1.3.1.1.jar";
      sha512 = "e9392854ae9a48dfd2612632e9bbfb05bddf1fe4d0511f5328647fe8b0f2d7ad19c8af0c4a271a5533bf984d1dde8e3d96d551dcbca723231923dd858507aee1";
      name = "moremobvariants-fabric+1.21-1.3.1.1.jar";
    })
    # arsenal-fabric-1.3.4+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/LiP9Q3KV/versions/gB8HeajH/arsenal-fabric-1.3.4%2B1.21.1.jar";
      sha512 = "e792f79474522da1745e7380a933a2859be79958686c34840c2072fd54297ca00ab1a509cd4381e805bd737b117c09d3dac813744b1002245bd6908cda60fe1f";
      name = "arsenal-fabric-1.3.4+1.21.1.jar";
    })
    # armory-fabric-1.2.10+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/PJvJUdGw/versions/dUUkoQRX/armory-fabric-1.2.10%2B1.21.1.jar";
      sha512 = "384065ca3d8c61a6a1eb1cf0519b0c4cb359b3c84391df02a86b178233ee67ee5b35cc3897a1518f114f86b51e87ff497aee24ddc22cbd4d28b85a42a0ee3c64";
      name = "armory-fabric-1.2.10+1.21.1.jar";
    })
    # durability_tweaks-fabric-1.0.0.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/HWQeS7qe/versions/8GNJinmL/durability_tweaks-fabric-1.0.0.jar";
      sha512 = "9e48db33c2cdb9d004a97d417303b92642f1b131a5336b9f0033ea00f285e48cd1f7d956e2bdbe2826ed266bc86cbe2c4e14d8dcb2c27a0b21e38fd53eb4fab8";
      name = "durability_tweaks-fabric-1.0.0.jar";
    })
    # relics-fabric-1.2.2+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/BDQucwF0/versions/KmnF0FA7/relics-fabric-1.2.2%2B1.21.1.jar";
      sha512 = "82d084caeb55380f801f0c8a42a61432137dd48e5ba0d0a9b6ad1c994236a95240ce879073ec917fbd281ce3dbf2c6ca044fe274e3eb10ef9f92aa144789a5ae";
      name = "relics-fabric-1.2.2+1.21.1.jar";
    })
    # skill_tree-fabric-1.2.3+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/PjDhruSC/versions/yRVKHR3V/skill_tree-fabric-1.2.3%2B1.21.1.jar";
      sha512 = "f1a2a23387ed2ec2bf5b1cfaeccd919dac94d5b80c5f0a8a4847c0de659027eb22145270f8ce53573a4082394875ca6af9dd13f94867dea52eb4bfaffbc084a4";
      name = "skill_tree-fabric-1.2.3+1.21.1.jar";
    })
    # village_taverns-fabric-1.1.5+1.21.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/bj4a8NjJ/versions/YU3Vmiqk/village_taverns-fabric-1.1.5%2B1.21.1.jar";
      sha512 = "14786d2b52bcca5ef4f7bb350fd62804577cc92305b7bd4ddc9290dd1bebfad6ab5682890e1ede5b6b3d5710374728af206e204eccd54cb6facfb2bd179b283e";
      name = "village_taverns-fabric-1.1.5+1.21.1.jar";
    })
    # connector-2.0.0-beta.12+1.21.1-full.jar (Sinytra Connector - allows NeoForge mods on Fabric)
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/u58R1TMW/versions/YCMXHxwl/connector-2.0.0-beta.12%2B1.21.1-full.jar";
      sha512 = "5d3746f9cf220c3592f1398f7b7380af265c91b465c3fbaa813f521c41ac022e9e5ce909b4251a05ef8c92c3b93a3ce7e0c081577ef8ec2ab2b4ca86d112799f";
      name = "connector-2.0.0-beta.12+1.21.1-full.jar";
    })
    # forgified-fabric-api-0.116.7+2.2.0+1.21.1.jar (Required for Connector)
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Aqlf1Shp/versions/tIUhtT2C/forgified-fabric-api-0.116.7%2B2.2.0%2B1.21.1.jar";
      sha512 = "59aa2599fde40dcaaf210ce7d9d7f9e665c9173370708d7337c7230f2f0eb894a4f130bfbfb78b612d4faad25353d03ceab42691b1b3bcacd924dd72434732ef";
      name = "forgified-fabric-api-0.116.7+2.2.0+1.21.1.jar";
    })
    # create-1.21.1-6.0.8.jar (NeoForge version, runs via Connector)
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/LNytGWDc/versions/88L641Un/create-1.21.1-6.0.8.jar";
      sha512 = "cb3ffee35ee2b2ab212fb4649e75ccfcb8e99ae954cf0b0251591062e3f200e5e639e8f40d7af7c79b7dc71164a027b0e6fbcd5c0bafe2da88f888fc3ffd254c";
      name = "create-1.21.1-6.0.8.jar";
    })
    # azurelibarmor-fabric-1.21.1-3.1.2.jar (Required by archers, armory_rpgs, paladins, rogues, wizards)
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/pduQXSbl/versions/V1h4or08/azurelibarmor-fabric-1.21.1-3.1.2.jar";
      sha512 = "34a8d7127d02acd56e98643b849cf9dea6ac0b7958a2f884173081475e2d2f4830fb173644775190bc9feb7a260ad5bfc0b2442f1b3239c6c97666cf671c065b";
      name = "azurelibarmor-fabric-1.21.1-3.1.2.jar";
    })
    # player-animation-lib-fabric-2.0.4+1.21.1.jar (Required by spell_engine, bettercombat, combat_roll)
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/gedNE4y2/versions/CkedfDp3/player-animation-lib-fabric-2.0.4%2B1.21.1.jar";
      sha512 = "14a931f5cf9f1a767c717a2ae65eb1041d3aab1fbb2c90e3f3a18433ed2f7264674fe40b85c136036fa08d2459543394b65e6866e73e8893e823c5ce37dfd086";
      name = "player-animation-lib-fabric-2.0.4+1.21.1.jar";
    })
    # pneumonocore-1.2.1+1.21+A.jar (Required by gravestones)
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/ZLKQjA7t/versions/QKvgjhTZ/pneumonocore-1.2.1%2B1.21%2BA.jar";
      sha512 = "028e18a7ec6719f67b3d2e2d0c57d207ff7ddf0b048d64c2dfed127566283aaafc17d70927d1c30259d4990ce0c12d5c177c4f5bbc2285a9163c08e29b364c28";
      name = "pneumonocore-1.2.1+1.21+A.jar";
    })
    # resourcefullib-fabric-1.21-3.0.12.jar (Required by handcrafted)
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/G1hIVOrD/versions/Hf91FuVF/resourcefullib-fabric-1.21-3.0.12.jar";
      sha512 = "df8a9586eaa0e2f8e1e6a5651ba79ff6c95327b0ab89cdab4708cc6ed51c3da6829d00e8f176e7e7b7b37d4af8c5bd9e3df047f3a8a04fd1af925d80c774185b";
      name = "resourcefullib-fabric-1.21-3.0.12.jar";
    })
    # architectury-13.0.8-fabric.jar (Required by nightlights)
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/lhGA9TYQ/versions/Wto0RchG/architectury-13.0.8-fabric.jar";
      sha512 = "7a24a0481732c5504b07347d64a2843c10c29e748018af8e5f5844e5ea2f4517433886231025d823f90eb0b0271d1fa9849c27e7b0c81476c73753f79f19302a";
      name = "architectury-13.0.8-fabric.jar";
    })
    # puffish_skills-0.17.1-1.21-fabric.jar (Required by skill_tree_rpgs)
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/hqQqvaa4/versions/l2HbUH41/puffish_skills-0.17.1-1.21-fabric.jar";
      sha512 = "d168d509bfe4202fd4a7dd94f7965fc48ebefb117fd71289598deba0925cab5b5bfc102a214978ee9cf28511e5f9362f1e3867d940b8feb7a6fd04d7d57c8042";
      name = "puffish_skills-0.17.1-1.21-fabric.jar";
    })
    # moonlight-1.21-2.29.3-fabric.jar (Required by smarterfarmers)
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/twkfQtEc/versions/XAvedFDj/moonlight-1.21-2.29.3-fabric.jar";
      sha512 = "d495d53a4567521f1260ea0e4dfdca95a8e69c884c591f0648afa96458d4cef73b2c070a6a16154148969935c50aecb9317b50f1343711d2598b9f275441bc3f";
      name = "moonlight-1.21-2.29.3-fabric.jar";
    })
    # bclib-21.0.13.jar (Required by betterend)
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/BgNRHReB/versions/TxWM7AW8/bclib-21.0.13.jar";
      sha512 = "93a5b45e4abcb27af6a8e8f662db9fd4115dfbb9e17adbce642f2217f5d09b48474d6b9e12b0673bdc663668e8d0d71b8fa23307c96c06176df55c090623a00c";
      name = "bclib-21.0.13.jar";
    })
    # worldweaver-21.0.13.jar (Required by betterend)
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/RiN8rDVs/versions/mPmeykPR/worldweaver-21.0.13.jar";
      sha512 = "d45470e9d1152f6ba0282a4005648738209d8f08bfdc72e147047dc0544ef2ba094689fb6d4d86ee2717dda38cb9fb01bb30743484e48dfb498c9a608ff24fcf";
      name = "worldweaver-21.0.13.jar";
    })
    # wunderlib-21.0.8.jar (Required by betterend)
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/8O0Adq7w/versions/NWOZ9B7R/wunderlib-21.0.8.jar";
      sha512 = "01d0000f985424ed7699d22d9cacd0de8be5eb375c1c3004d1a38775f200938cfef5c42ab5fd3b6525752ec3f208c3655e51b2e5f6012f45e559454bfbd6e649";
      name = "wunderlib-21.0.8.jar";
    })
  ];

  # Resource packs configuration
  resourcepacks = pkgs.linkFarmFromDrvs "resourcepacks" [
    # FreshAnimations_v1.10.3.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/50dA9Sha/versions/F9QwVhGH/FreshAnimations_v1.10.3.zip";
      sha512 = "713dd4e810a59d84844e25fa5fb3e36c83ac2e197d5259e16b61d4b4899f1a3f8bacdd4d4e5d0f5cde9a3497fad5e50ccea0c6270898f53f802e340e3fb3e73f";
      name = "FreshAnimations_v1.10.3.zip";
    })
    # MoreMobVariants_FreshAnimations_1.3.1-1.9.2.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/ZrnmXWf6/versions/uIOGuHMy/MoreMobVariants_FreshAnimations_1.3.1-1.9.2.zip";
      sha512 = "262573dd4bc91133d6d5c7abb751345533b82c1d34f694ee555c50089720a90b1aa345300a1fea216aa9aa08a8e58f04b5a2e6a57a75d6027cddfd2a96afa962";
      name = "MoreMobVariants_FreshAnimations_1.3.1-1.9.2.zip";
    })
    # Dramatic_Skys_Demo_1.5.3.36.2.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/2YyNMled/versions/Y8mjFzcP/Dramatic%20Skys%20Demo%201.5.3.36.2.zip";
      sha512 = "00f62d91a67bc00f83ff5be65d11cdb71f2386583dd4fec26f036b2fc400b4a37a6c404a237bf4dfd479da0230c28125a4dec86799dc0cc691d5bde863bc30a1";
      name = "Dramatic_Skys_Demo_1.5.3.36.2.zip";
    })
    # Better-Leaves-9.4.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/uvpymuxq/versions/JW14JsXq/Better-Leaves-9.4.zip";
      sha512 = "d6969d044a6e48468b3637e29e0d6afa9af4618bf20bf28db7e3c588ea6bbd2f3a4cf9f154524249fe154b4ff8fb7ccc8c59099fd9ccc6d6bec714ae56ea2102";
      name = "Better-Leaves-9.4.zip";
    })
    # Fresh_Moves_v3.1.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/slufHzC2/versions/lHNQh6Gv/-1.21.2%20Fresh%20Moves%20v3.1%20%28No%20Animated%20Eyes%29.zip";
      sha512 = "ac0cb4207d3b20fd94e899b63e7a29cf7e1836cb711181f94d72be5ecb8454293a87135998f7298628dc88b2cb79d59a9be2ea1cd9ebfb24ef5d1e2a16e4361c";
      name = "Fresh_Moves_v3.1.zip";
    })
    # LowOnFire_1.21.3.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/RRxvWKNC/versions/QL8e10aI/LowOnFire%201.21.3.zip";
      sha512 = "2a6bcdd6963996af35474fc12cd4a57163d1435d2f8b61383eb269ca66297e80d6b687343fc7f151d4111719e05ae90020c3b4d1075bf9e1c33765cc3f68748f";
      name = "LowOnFire_1.21.3.zip";
    })
    # FA+All_Extensions-v1.7.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/YAVTU8mK/versions/hGa4E44T/FA%2BAll_Extensions-v1.7.zip";
      sha512 = "4c7e8ead077cf2da3005e23a1928417374be8f27513fe4ec24c49f8eabd0305e3e57cba073228b4f851b7035d491f0f64c37dd28f3a5fb315a5d05c930233a89";
      name = "FA_All_Extensions-v1.7.zip";
    })
    # cubic-sun-moon-v1.8.1a.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/g4bSYbrU/versions/3svw5AHq/cubic-sun-moon-v1.8.1a.zip";
      sha512 = "1112fd0411fb739b3b047d9ced2d5d85d35a10e9a44ae277721dcfe490b6ec5cdd64e62a0fce5e96a309ec2153d66c542fce3633195841f665bf424b7b1bf749";
      name = "cubic-sun-moon-v1.8.1a.zip";
    })
    # Low_Shield.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/CZrLuVQo/versions/bDbgSHEM/Low%20Shield.zip";
      sha512 = "aac76c9f32d87e2aae42a77f39d10dc978d4095017f6d85eb541b357e46a791e35b9ae65c5fece84ae34fe464b9ed26a1532c805dda617100ac8a1eef320114e";
      name = "Low_Shield.zip";
    })
    # Fresh_Food_1.1.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/UoLAbzII/versions/CRI4mlJe/Fresh%20Food%201.1%20-%201.20.1-1.21.1.zip";
      sha512 = "7079b9d28b4d28db27409e2df4240fb9c43b737386ab133498f7a7b9cd13efabf2c369d5f0a621892132d77b6c499dbf749a7687fe055e0f905e72cdbed945a1";
      name = "Fresh_Food_1.1.zip";
    })
  ];

  # Datapacks configuration
  datapacks = pkgs.linkFarmFromDrvs "datapacks" [
    # tectonic-datapack-3.0.18.zip
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/lWDHr9jE/versions/VfuqmXvF/tectonic-datapack-3.0.18.zip";
      sha512 = "3de178cc019f481d86511d66c579317a1277167685d7886707ae591f25cc910cb2d5550ef77d69c2d35b0acdb2c67b05f7ef014c45a9feda2867281227d85e81";
      name = "tectonic-datapack-3.0.18.zip";
    })
  ];
in {
  config = mkIf cfg.enable {
    services.minecraft-servers = {
      enable = true;
      eula = true;
      dataDir = "/var/lib/minecraft";

      servers.main = {
        enable = true;
        # Using Fabric server for mod support with Java 25 for c2me-opts-natives-math compatibility (requires Java 22+)
        package = pkgs.fabricServers.fabric-1_21_1.override {
          jre_headless = pkgs.temurin-jre-bin-25;
        };
        openFirewall = true;
        jvmOpts = "-Xms2048m -Xmx6656m -Dminecraft.data.allowSymlinks=true";

        serverProperties = {
          difficulty = "hard";
          gamemode = "survival";
          max-players = 3;
          view-distance = 64;
          simulation-distance = 8;
          motd = "D&J Minecraft Server";
          white-list = true;
        };

        whitelist = {
          Trospar = "79995c56-739b-4e4d-a6a7-c6b15781565d";
          PumpkinStigen = "5601a49d-1242-41f3-aaf5-13a995617132";
        };

        # Mods configuration using modpack
        symlinks = {
          "mods" = modpack;
          "resourcepacks" = resourcepacks;
        };

        # Datapacks copied as files to satisfy Minecraft 1.21.1 validation
        files = {
          "world/datapacks" = datapacks;
        };
      };
    };
  };
}
