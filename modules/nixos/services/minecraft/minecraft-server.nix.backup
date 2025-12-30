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
    # almanac-1.20.x-fabric-1.0.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Gi02250Z/versions/QM6nx1Sa/almanac-1.20.x-fabric-1.0.2.jar";
      sha512 = "4e3d83ac58971e3073fce1ee48094ee4c8c2ef97bf5abf4e3af5f3a25c32190bcefd970e85b360c665f192b563e736e5bcde820787fa7f13088999163a0d083a";
      name = "almanac-1.20.x-fabric-1.0.2.jar";
    })
    # appleskin-fabric-mc1.20.1-2.5.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/EsAfCjCV/versions/xcauwnEB/appleskin-fabric-mc1.20.1-2.5.1.jar";
      sha512 = "1544c3705133694a886233bdf75b0d03c9ab489421c1f9f30e51d8dd9f4dcab5826edbef4b7d477b81ac995253c6258844579a54243422b73446f6fb8653b979";
      name = "appleskin-fabric-mc1.20.1-2.5.1.jar";
    })
    # carpet-fixes-1.20-1.16.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/7Jaxgqip/versions/NBCnBGZj/carpet-fixes-1.20-1.16.1.jar";
      sha512 = "6f3bb939ae660d7b85b3d258f7fe1431792d10f20d14d67b37130cd44fcb70cb6fbf6a51953cd6ab3f29699dd6073b8174baa08c044ac8b9a26d0f2fe88033a6";
      name = "carpet-fixes-1.20-1.16.1.jar";
    })
    # fabric-carpet-1.20-1.4.112+v230608.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/TQTTVgYE/versions/K0Wj117C/fabric-carpet-1.20-1.4.112%2Bv230608.jar";
      sha512 = "bf9060e6b1d30d676d9efd30369ccb5baef164fc2d87aad7c7a19d2d9265b5d1d328428a308bdd15960a26bfe46dcd823a236c39f4e26474847354337b043c51";
      name = "fabric-carpet-1.20-1.4.112+v230608.jar";
    })
    # cloth-config-15.0.140-fabric.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/9s6osm5g/versions/HpMb5wGb/cloth-config-15.0.140-fabric.jar";
      sha512 = "1b3f5db4fc1d481704053db9837d530919374bf7518d7cede607360f0348c04fc6347a3a72ccfef355559e1f4aef0b650cd58e5ee79c73b12ff0fc2746797a00";
      name = "cloth-config-15.0.140-fabric.jar";
    })
    # Cobblemon-fabric-1.5.2+1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/MdwFAVRL/versions/EVozVxCq/Cobblemon-fabric-1.5.2%2B1.20.1.jar";
      sha512 = "38f6e1ae17673f9c62915ebc68558b1c50cf4c2bdeb299ac06aed84ecf0bf9c56732cbc123252f43ea3abee10d3348c50b74fa46cac6d9d8dd0c11833bacaabe";
      name = "Cobblemon-fabric-1.5.2+1.20.1.jar";
    })
    # collective-1.20.1-8.13.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/e0M1UDsY/versions/9fUQXa48/collective-1.20.1-8.13.jar";
      sha512 = "bc6136fbec7447ef3d7ecd150dc3f531f7980e8dea95c638cbb06ddef1f28aeadd72a214baff0232fd2fd28f931061b7571f4f1fb7acf6fc1c08965ea481cfda";
      name = "collective-1.20.1-8.13.jar";
    })
    # conduitspreventdrowned-1.20.1-3.9.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/kpKchl4x/versions/bDA25Xcg/conduitspreventdrowned-1.20.1-3.9.jar";
      sha512 = "264eeb1d848ee611049e441b69247e77ceaf8a35c30f55dd5fbbad1be41da22803d9cd14f1fb90d74e07bb88d82fa922d60c4a5743356a285534defb3fc69612";
      name = "conduitspreventdrowned-1.20.1-3.9.jar";
    })
    # coroutil-fabric-1.20.1-1.3.7.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/rLLJ1OZM/versions/7tRnsYkP/coroutil-fabric-1.20.1-1.3.7.jar";
      sha512 = "4a03363dd9cfd517eb04bea77779c88e74f12c1dacadc726869cb9b595348d615e50041893ad72155f7ac2c359219604710d6157dec95a46fe0e598ef5642035";
      name = "coroutil-fabric-1.20.1-1.3.7.jar";
    })
    # clockwork-fabric-0.5.3-[MELTING_POINT].jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/84USeAvk/versions/Jsckttl2/clockwork-fabric-0.5.3-%5BMELTING_POINT%5D.jar";
      sha512 = "67e7eed11f4c8a9f7a92fee73b4a0a548f065e4eac2dd28926238c6b8d19f6c0f113da720ee6b198be557aea75347a3a011977f56b71c2a16486bbc49a9e1504";
      name = "clockwork-fabric-0.5.3-[MELTING_POINT].jar";
    })
    # create-fabric-6.0.8.1+build.1744-mc1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Xbc0uyRg/versions/HAqwA6X1/create-fabric-6.0.8.1%2Bbuild.1744-mc1.20.1.jar";
      sha512 = "6edaddb93bc87bf8204376d3ceddd3e3dfec1d716556a5925802f2ade59ce5a660ded50088fa94188842ff83fc29445363dfa5d423e425b1574092833b6fa896";
      name = "create-fabric-6.0.8.1+build.1744-mc1.20.1.jar";
    })
    # dismountentity-1.20.1-3.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/H7N61Wcl/versions/8dvHq4gs/dismountentity-1.20.1-3.6.jar";
      sha512 = "071f0596af218aebabaeae1cdd52c9c2e712c96969df80c4635c1b810afa6605cb5459ffb92b23d89d4b46be9330a185edaea8c5ed39b71477066d49daefc934";
      name = "dismountentity-1.20.1-3.6.jar";
    })
    # doubledoors-1.20.1-7.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/JrvR9OHr/versions/JxWWE54a/doubledoors-1.20.1-7.2.jar";
      sha512 = "335774b5052d6b557c1e6b93197e1f4c19b9f1edeca7482d1e87d03a95a6e34588554481b299238938dbdaf6159594da544874e51dc96f27ca7d4cef62d76897";
      name = "doubledoors-1.20.1-7.2.jar";
    })
    # dragondropselytra-1.20.1-3.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/DPkbo3dg/versions/VjJgkK28/dragondropselytra-1.20.1-3.5.jar";
      sha512 = "8be91fa55e676f592abd59e76cf507a368c783d0dc272145a21838be8e0b50ab350be71b63fb7a379dcd80048970b69a44a1ff8404ce1b7413abadda05c88636";
      name = "dragondropselytra-1.20.1-3.5.jar";
    })
    # easyelytratakeoff-1.20.1-4.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/3hqwGCUB/versions/JBhBlmby/easyelytratakeoff-1.20.1-4.5.jar";
      sha512 = "21490ad2524bfd094fa21ebc14c12e943a77bb90fa384ded24a83ecd40c0c579d85635b1e45a27bb38ab450279268cdb09f77d6325203f38e580775e5e5bbe28";
      name = "easyelytratakeoff-1.20.1-4.5.jar";
    })
    # fabric-api-0.100.4+1.21.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/oIVA3FbL/fabric-api-0.100.4%2B1.21.jar";
      sha512 = "CEle0tUC/gFxn+VfSf8LEG/duKkuGxe7drT/FZCjyba27WAcsqN83guzE5wsq/AFP+LdPWzojSZkgM80mWwLHg==";
      name = "fabric-api-0.100.4+1.21.jar";
    })
    # ferritecore-6.0.1-fabric.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/uXXizFIs/versions/unerR5MN/ferritecore-6.0.1-fabric.jar";
      sha512 = "9b7dc686bfa7937815d88c7bbc6908857cd6646b05e7a96ddbdcada328a385bd4ba056532cd1d7df9d2d7f4265fd48bd49ff683f217f6d4e817177b87f6bc457";
      name = "ferritecore-6.0.1-fabric.jar";
    })
    # geckolib-fabric-1.21-4.5.8.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/8BmcQJ2H/versions/11VBhLU2/geckolib-fabric-1.21-4.5.8.jar";
      sha512 = "3d6f5e5b05ff9eb033dbb9d621b4494d891f31af069787fcaccf23cf3a179fc5ed9f25c26218480058c4330b72b488659be536ced2f2b9da24b3757041417338";
      name = "geckolib-fabric-1.21-4.5.8.jar";
    })
    # healingcampfire-1.20.1-6.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/kOuPUitF/versions/olxRjKsI/healingcampfire-1.20.1-6.2.jar";
      sha512 = "141603dc3ab64744dbd1eef380b386dfcf606230186185f8d5cb98ca44034aa9d774820ab81ff273ec30e417afcf6d733768e98d6cfe120fe840a0c375e1f0e3";
      name = "healingcampfire-1.20.1-6.2.jar";
    })
    # infinitetrading-1.20.1-4.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/U3eoZT3o/versions/DkRq9YKI/infinitetrading-1.20.1-4.6.jar";
      sha512 = "db19f120498b3cbe955e7eea4c76cbd6c3c243f359dc03ab151cd57d6bf49e529e4f7b8882530dc1a79ee2dca956465175ccddef2ac3d24d5ad810e309bdae7d";
      name = "infinitetrading-1.20.1-4.6.jar";
    })
    # inventorytotem-1.20.1-3.4.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/yQj7xqEM/versions/FdstVlDW/inventorytotem-1.20.1-3.4.jar";
      sha512 = "1ade16e67b8bf42d8479312763ebf44ffdbc2fb257eecc157679fc2aa7226b8d79f068c01d7af262dde66d489c261ede99613915b45e59ce2699548cbd377cd7";
      name = "inventorytotem-1.20.1-3.4.jar";
    })
    # justplayerheads-1.20.1-4.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/YdVBZMNR/versions/8vQWn1zu/justplayerheads-1.20.1-4.2.jar";
      sha512 = "99c61f91e78881068cdcdfb9a9e0fb51b292940fcbb6f2e807d05404b757b4ac7e2f3ecb0eed4a3de2552101f41bf5fd857b7c344f3a5981a984444d215edb78";
      name = "justplayerheads-1.20.1-4.2.jar";
    })
    # keepmysoiltilled-1.20.1-2.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/OC5Zubbe/versions/WLWL44CC/keepmysoiltilled-1.20.1-2.5.jar";
      sha512 = "2c2daacd0c8ed3cd089c3f7810f762a4064a74eb7a353194bf826508c812c5d152326856f798f2d5c136bfc81f2c388c566f3a4ac69cb0099058d25ab0357f0a";
      name = "keepmysoiltilled-1.20.1-2.5.jar";
    })
    # krypton-0.2.3.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/fQEb0iXm/versions/jiDwS0W1/krypton-0.2.3.jar";
      sha512 = "92b73a70737cfc1daebca211bd1525de7684b554be392714ee29cbd558f2a27a8bdda22accbe9176d6e531d74f9bf77798c28c3e8559c970f607422b6038bc9e";
      name = "krypton-0.2.3.jar";
    })
    # lithium-fabric-mc1.20.1-0.11.4.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/iEcXOkz4/lithium-fabric-mc1.20.1-0.11.4.jar";
      sha512 = "31938b7e849609892ffa1710e41f2e163d11876f824452540658c4b53cd13c666dbdad8d200989461932bd9952814c5943e64252530c72bdd5d8641775151500";
      name = "lithium-fabric-mc1.20.1-0.11.4.jar";
    })
    # letmedespawn-1.20.x-fabric-1.5.0.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/vE2FN5qn/versions/rOkgwJ12/letmedespawn-1.20.x-fabric-1.5.0.jar";
      sha512 = "9cd165f407e16445d70d3ba916df732e41b769384a133b08291d400fed20c3f1a00a225e81b693542e914917e10ab5b7dc1c9ca62c5c596f76453fdcf010ff41";
      name = "letmedespawn-1.20.x-fabric-1.5.0.jar";
    })
    # midnightlib-fabric-1.9.2+1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/codAaoxh/versions/jyowrZ5N/midnightlib-fabric-1.9.2%2B1.20.1.jar";
      sha512 = "9c22d8478151d9a81d69b2da04274db1e1d9b50056319fd8545bb09340794ae364d8525340878dcd39035d49e54eb66530394bba28d3424f7a0a4ff530f7d1c9";
      name = "midnightlib-fabric-1.9.2+1.20.1.jar";
    })
    # mineralchance-1.20.1-3.8.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/bu1hACOl/versions/ivqjJxmM/mineralchance-1.20.1-3.8.jar";
      sha512 = "6550936fb0947dfbddb75ddb5a8ba6c3a4f66b4e8cb0fd264af0affae57779cc4ab28fe04fa669dfdaf3d5621f6f43aeac5a7edf139e98612be3974e2469c8ac";
      name = "mineralchance-1.20.1-3.8.jar";
    })
    # mobtimizations-fabric-1.20.1-1.0.0.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Kbz7UydC/versions/Q8aBGBRu/mobtimizations-fabric-1.20.1-1.0.0.jar";
      sha512 = "972ab7947d920035c03cc5c05357a405f276b5d9e291b74280f67906185f8e8475dd41dc3df6f99f83fc22c9a831627ddf720de074c78b9c024094f594979e18";
      name = "mobtimizations-fabric-1.20.1-1.0.0.jar";
    })
    # modernfix-fabric-5.25.2+mc1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/nmDcB62a/versions/rPmgLeZC/modernfix-fabric-5.25.2%2Bmc1.20.1.jar";
      sha512 = "878e39d182767ffd08ad6a3539fae780739129db133abe02b9b73dc3df6e1ac9ddbe509620356b0aae5e7bfbed535d0e18741703334317a16fefef820269da2d";
      name = "modernfix-fabric-5.25.2+mc1.20.1.jar";
    })
    # nametagtweaks-1.20.1-4.0.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/LrLZEnPl/versions/xFDnAS8R/nametagtweaks-1.20.1-4.0.jar";
      sha512 = "1ff3ecc2ca7968b9a6f559d7979503ba571f79c9f34bebe17333b83671b4855a87775f36f7aaa151d271a5a1647cbe8131d0d4fad425211a6ad326b4f62c34f8";
      name = "nametagtweaks-1.20.1-4.0.jar";
    })
    # nohostilesaroundcampfire-1.20.1-7.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/EJqeyaVz/versions/iNnx7a2g/nohostilesaroundcampfire-1.20.1-7.2.jar";
      sha512 = "1eae3222ec664b0d86567bff76e84736564bd294ceb444cf7e8027a13a7f2136d81704c3c1876b3e321daff82d978bfa75ac04066925e0a21db9d9d4ae9b41f7";
      name = "nohostilesaroundcampfire-1.20.1-7.2.jar";
    })
    # oreharvester-1.20.1-1.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Xiv4r347/versions/nDJbf1ba/oreharvester-1.20.1-1.5.jar";
      sha512 = "11371f850b1b6531df94043599b83a89308123113a3ca5349581eb6ae1787e151e83d368cbfb5ff9d1f1b056be930f32367608d43ae43cf7f1638e13ef332584";
      name = "oreharvester-1.20.1-1.5.jar";
    })
    # passiveshield-1.20.1-3.7.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/iQBrasyH/versions/A1S3DRBc/passiveshield-1.20.1-3.7.jar";
      sha512 = "4282e9eb21ccb5aaa638b9c5329a0f7c914e58ef33e9b2a477aab9f81d6730956d2aefa1e3eed0e45d6bb4fcf4c33d4dd2b1c8743706ab919a5facba1addc997";
      name = "passiveshield-1.20.1-3.7.jar";
    })
    # Paxi-1.21.1-Fabric-5.1.3.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/CU0PAyzb/versions/FfXyVbds/Paxi-1.21.1-Fabric-5.1.3.jar";
      sha512 = "731250638cb764affc83b589ee3ee9ab233a80a64ca2dfdebce0772c174e62554e6622ceccc693a0ae8bc4a24537c16584161cbcb84a6877c7cb97e575a03f17";
      name = "Paxi-1.21.1-Fabric-5.1.3.jar";
    })
    # replantingcrops-1.20.1-5.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/EXzIPtJo/versions/JrbAOCLs/replantingcrops-1.20.1-5.5.jar";
      sha512 = "bcaad1c18addac1470d9fb16197add1a419f886aa0372359639f1c7037b068bbf4ddb95ca4a3e07c149cb01877da0322d118e92f3154263fd907e51cd4aba88c";
      name = "replantingcrops-1.20.1-5.5.jar";
    })
    # respawningshulkers-1.20.1-4.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/gHCmhGUV/versions/PGGBTZmK/respawningshulkers-1.20.1-4.1.jar";
      sha512 = "0de5f26831ee90d70631a2b2c9003f4824e0cc034339354051d554753cd3ced0a618a2e8719540f20d0f184bac21773186da34e38b6c3babf03135a7e9f53d39";
      name = "respawningshulkers-1.20.1-4.1.jar";
    })
    # Ribbits-1.21.1-Fabric-4.1.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/8YcE8y4T/versions/O3uPSYcc/Ribbits-1.21.1-Fabric-4.1.6.jar";
      sha512 = "00829624b226afbf75587d4cfdb8cbefaefec55acaa7aad4aae70f65fdf1cbe3edfc61bb2cf28c41d96a6b20ba0dad52dadb35dd21378ff28b39cf42f238662e";
      name = "Ribbits-1.21.1-Fabric-4.1.6.jar";
    })
    # shulkerdropstwo-1.20.1-3.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/UjXIyw47/versions/89tfEaAo/shulkerdropstwo-1.20.1-3.5.jar";
      sha512 = "072d5d7c11fc7498572e873ea993a94c277feee1268de29c41b242098286be0494a9648528e62148bc091c6072f19b4ebef8a0ec82578fed38a2bc17d5062c5d";
      name = "shulkerdropstwo-1.20.1-3.5.jar";
    })
    # smallernetherportals-1.20.1-3.9.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/fYAofsi6/versions/AKAgpUev/smallernetherportals-1.20.1-3.9.jar";
      sha512 = "9ecae52cc42fe3edc1a45b157d495cddf867975d1f63a6c3aa65e732eeac40ac5bae3e3d1269cd342fe077e548e67cd7b9f05a1a3e760447162f192c4cfca91b";
      name = "smallernetherportals-1.20.1-3.9.jar";
    })
    # spidersproducewebs-1.20.1-3.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/NoznOJXq/versions/lnhVp9FD/spidersproducewebs-1.20.1-3.6.jar";
      sha512 = "76f33d3cbb3f9581d33ce16fafd36c63372e13b2c5fcd969b485bb008b2ab6b69488fbe74f98090fdb01e5208a66b9e87f9648ac0c6d3a3d914d24fd98ec69d1";
      name = "spidersproducewebs-1.20.1-3.6.jar";
    })
    # stackrefill-1.20.1-4.9.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/mQWkB9ON/versions/3w2JG23r/stackrefill-1.20.1-4.9.jar";
      sha512 = "0bde00bbc05c9c1e17bd3257d28919a96a8ef8a494ddeafb88ca9cc0db0e928bd5253f59f6d9a843dcab5062704f5232b886459e49717e6779b20d20ae422b77";
      name = "stackrefill-1.20.1-4.9.jar";
    })
    # TerraBlender-fabric-1.21-4.0.0.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/kkmrDlKT/versions/N1JhLbFM/TerraBlender-fabric-1.21-4.0.0.2.jar";
      sha512 = "27fff2e0bb73b616e2390dbfff5f646b139a645d9910f7e395e1ff9ee49797db70b8a1deebc4c278fef09564d740e15531287a4a01ad5ae094af7f1948f5b055";
      name = "TerraBlender-fabric-1.21-4.0.0.2.jar";
    })
    # treeharvester-1.20.1-9.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/abooMhox/versions/EQYmDYvI/treeharvester-1.20.1-9.1.jar";
      sha512 = "eab24be8a6b75ed03dcd9b324acb6f79145839836faa9829546a663e2cc782e4dd49323a9300e832105b02e44dd642b3994d6ad49c6dcc485d6f9f14136cdc15";
      name = "treeharvester-1.20.1-9.1.jar";
    })
    # valkyrienskies-120-2.4.3.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/V5ujR2yw/versions/PfzMKWLM/valkyrienskies-120-2.4.3.jar";
      sha512 = "a73e063ba9f3d7671f2329c3e3890bc51c4eb17a68087c613ebf4113e90a7f434442f4f33120151aa24401c037dcf564a1aaf10dd46907e0dae14f8e10df11e0";
      name = "valkyrienskies-120-2.4.3.jar";
    })
    # villagernames-1.20.1-8.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/gqRXDo8B/versions/hvhPwZZ6/villagernames-1.20.1-8.2.jar";
      sha512 = "6315c0f723c35f5420b720b481aecc524f3311d01ac60627425a99face0367b5aedf50f324a0a3a197c1cacf9f09efb47449dc70284e72311c19ad193e19f34b";
      name = "villagernames-1.20.1-8.2.jar";
    })
    # Xaeros_Minimap_25.2.10_Fabric_1.20.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/1bokaNcj/versions/1Knv1cKY/Xaeros_Minimap_25.2.10_Fabric_1.20.jar";
      sha512 = "5a0df7750c5b8f2a97e8756a42fc90ba8242b615d92a19e8f6ee7fdfc7dbc168806a30232971a8b39691ad8a97c7a8a112b99a1b2a8277d9b10b0cf9338a6cae";
      name = "Xaeros_Minimap_25.2.10_Fabric_1.20.jar";
    })
    # XaerosWorldMap_1.39.12_Fabric_1.20.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/NcUtCpym/versions/XBgSFzXh/XaerosWorldMap_1.39.12_Fabric_1.20.jar";
      sha512 = "f84a3f3d1794a6da7ab96ea7ac08ab776df6a3f51f4fc02dc49fb5ef57518eb02cee308805622e71b383f195749c41b3bb33ea1ec252893f26ec89accf7fb854";
      name = "XaerosWorldMap_1.39.12_Fabric_1.20.jar";
    })
    # YungsApi-1.21.1-Fabric-5.1.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Ua7DFN59/versions/9aZPNrZC/YungsApi-1.21.1-Fabric-5.1.6.jar";
      sha512 = "fc05fb3941851cfa5c8e89f98704938a5b0581f66fe3b1b0d83b2f46f1cb903e1e1070f40c92a82da91813b36452358d6b2df7dc42a275f459dc5030ea467cb6";
      name = "YungsApi-1.21.1-Fabric-5.1.6.jar";
    })
    # YungsBetterCaves-1.21.1-Fabric-3.1.4.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Dfu00ggU/versions/72UkhXm7/YungsBetterCaves-1.21.1-Fabric-3.1.4.jar";
      sha512 = "347306c83e1d4f8381e2db410b4ee03e4d2b0f13846fefe33bead3fc85ff78a372e477a930c7251bb44f8d6d7841ce7719239562b6e8f6fcd3298741363f6cae";
      name = "YungsBetterCaves-1.21.1-Fabric-3.1.4.jar";
    })
    # YungsBetterDesertTemples-1.21.1-Fabric-4.1.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/XNlO7sBv/versions/M6eeDRkC/YungsBetterDesertTemples-1.21.1-Fabric-4.1.5.jar";
      sha512 = "2bed532391cd1f2e5ed7986220f3b4c23d0c1302366b61baf1ca62a9620000bd58964cfd9a62fc52abbc95e76c1b3a4f85fbe88ca0a4006612f0493585c99084";
      name = "YungsBetterDesertTemples-1.21.1-Fabric-4.1.5.jar";
    })
    # YungsBetterDungeons-1.21.1-Fabric-5.1.4.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/o1C1Dkj5/versions/fQ7EjDPE/YungsBetterDungeons-1.21.1-Fabric-5.1.4.jar";
      sha512 = "4a11b1b1f845ddd1709e6a6cad6c6d5043704afbd4b97cb2afcd316f8fdcf6e398f8dd55480d02e32326ac5b49b6b273ec99cd2b1e311bed24f786e6d176612c";
      name = "YungsBetterDungeons-1.21.1-Fabric-5.1.4.jar";
    })
    # YungsBetterEndIsland-1.21.1-Fabric-3.1.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/2BwBOmBQ/versions/zpUYcjIg/YungsBetterEndIsland-1.21.1-Fabric-3.1.2.jar";
      sha512 = "b26e84469e6d66bbc2deefec0b6ed7d93db2b374d7c4bb495e7178e668efb320a5793b42c1b0dd08f71513a4c25faee881e8d81b64eadacb1c34af1619a0f6cf";
      name = "YungsBetterEndIsland-1.21.1-Fabric-3.1.2.jar";
    })
    # YungsBetterJungleTemples-1.21.1-Fabric-3.1.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/z9Ve58Ih/versions/uiGCmR8O/YungsBetterJungleTemples-1.21.1-Fabric-3.1.2.jar";
      sha512 = "0b2912606607e4e85cd9b713c3d08986c4e7662da8964cad86d230ef13f57fd53adc7b7447145db95c6c3e9c85edb6c3a115a9f3126965855577792e29876e97";
      name = "YungsBetterJungleTemples-1.21.1-Fabric-3.1.2.jar";
    })
    # YungsBetterMineshafts-1.21.1-Fabric-5.1.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/HjmxVlSr/versions/4ybDuGhA/YungsBetterMineshafts-1.21.1-Fabric-5.1.1.jar";
      sha512 = "f19c53ecac52866f65e1791f7b46ecc68fff6b1912ac47b42bf64097012262691c7184ea4a95db5e7bfcfda6c9532138dfe29e29af4ab108a407807a8db28074";
      name = "YungsBetterMineshafts-1.21.1-Fabric-5.1.1.jar";
    })
    # YungsBetterNetherFortresses-1.21.1-Fabric-3.1.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Z2mXHnxP/versions/gxBGYcIL/YungsBetterNetherFortresses-1.21.1-Fabric-3.1.5.jar";
      sha512 = "74f9327ce3d17e78bef1945d6b241498f517e6e5ffae37c5c7a8acdc15b53bebf7447644517f76c4cecbf8a8530a888b6ee5035cf4f3b8e9441a2f665f7385d3";
      name = "YungsBetterNetherFortresses-1.21.1-Fabric-3.1.5.jar";
    })
    # YungsBetterOceanMonuments-1.21.1-Fabric-4.1.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/3dT9sgt4/versions/TGK6gpeO/YungsBetterOceanMonuments-1.21.1-Fabric-4.1.2.jar";
      sha512 = "2ad568affe005aa49be225ca1ce43272d773140dee7053ee4a5981288b5ef7ee92536a1d041ae3f00b6399de2f499abd1bf905cfbb764d569a99dd9b2cf8841f";
      name = "YungsBetterOceanMonuments-1.21.1-Fabric-4.1.2.jar";
    })
    # YungsBetterStrongholds-1.21.1-Fabric-5.1.3.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/kidLKymU/versions/uYZShp1p/YungsBetterStrongholds-1.21.1-Fabric-5.1.3.jar";
      sha512 = "01e467a5237a338d8347b79d2e99659a362b777c4ac10bf6e75382be072b645277b58c655b9b4ad69956f9836601c3a52c733ad437d1f6bd53ea13976545edaa";
      name = "YungsBetterStrongholds-1.21.1-Fabric-5.1.3.jar";
    })
    # YungsBetterWitchHuts-1.21.1-Fabric-4.1.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/t5FRdP87/versions/bdpPtvTn/YungsBetterWitchHuts-1.21.1-Fabric-4.1.1.jar";
      sha512 = "ca6749bd01cd5b623d6f58561a57c2e2a8f769c31e3947fceac22e495f5da5b803d05777c6e3e122da40c4dd49444d58aaface0220b0a3106a5b5e27658b2d9f";
      name = "YungsBetterWitchHuts-1.21.1-Fabric-4.1.1.jar";
    })
    # YungsBridges-1.21.1-Fabric-5.1.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Ht4BfYp6/versions/8h9N9fvs/YungsBridges-1.21.1-Fabric-5.1.1.jar";
      sha512 = "435c18442ca94c3b44a6972dddca7ca0f2437427627340b1c5aab7ac41001c9d9e5225de34b493acb0fec57f0fc1fe93818e0dc05d76bb059c6608e0155efb2f";
      name = "YungsBridges-1.21.1-Fabric-5.1.1.jar";
    })
    # YungsCaveBiomes-1.21.1-Fabric-3.1.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/cs7iGVq1/versions/geZa9lJS/YungsCaveBiomes-1.21.1-Fabric-3.1.1.jar";
      sha512 = "b7fd6386b6652366a950375d352f011310fb40c14aef668d9cf1a4f63080ae3d6b46db302117a32359fbff3327b23b7275f0e39b487e9261f2e5b66a3dbe0409";
      name = "YungsCaveBiomes-1.21.1-Fabric-3.1.1.jar";
    })
    # YungsExtras-1.21.1-Fabric-5.1.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/ZYgyPyfq/versions/aVsikHca/YungsExtras-1.21.1-Fabric-5.1.1.jar";
      sha512 = "a5b3281fc482167864745df34d80c834c42aa434f372ebb6ccb0cd84a8882ce344c247db5a8dea0300fe30ef39e2a85fa650216ff12adeb6c435e182e0ae2e55";
      name = "YungsExtras-1.21.1-Fabric-5.1.1.jar";
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
        # Using Fabric server for mod support
        package = pkgs.fabricServers.fabric-1_20_1;
        openFirewall = true;
        jvmOpts = "-Xms2048m -Xmx6656m";

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
        };
      };
    };
  };
}
