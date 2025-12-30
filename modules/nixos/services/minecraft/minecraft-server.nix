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
    # AmbientSounds_FABRIC_v6.3.1_mc1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/fM515JnW/versions/izo1gsEI/AmbientSounds_FABRIC_v6.3.1_mc1.20.1.jar";
      sha512 = "e428b51dc0a5b2fc4d0700c004e88c3be77fba56be382f179b857078f939c37523bb9d72de7e719e4615aed63999ae002bca4acd8b592b9e1d8bf44b04d26319";
      name = "AmbientSounds_FABRIC_v6.3.1_mc1.20.1.jar";
    })
    # animatica-0.6.1+1.20.4.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/PRN43VSY/versions/M2xzBL7h/animatica-0.6.1%2B1.20.4.jar";
      sha512 = "50b5d89d2a52a62496c6d459d528341e26d6d3836df3098b58da06a0907d28badfa4ae2ce1635ae48c729d8824f3f0ef9a32de10c77461b33cc04fe3a5da1662";
      name = "animatica-0.6.1+1.20.4.jar";
    })
    # appleskin-fabric-mc1.20.1-2.5.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/EsAfCjCV/versions/xcauwnEB/appleskin-fabric-mc1.20.1-2.5.1.jar";
      sha512 = "1544c3705133694a886233bdf75b0d03c9ab489421c1f9f30e51d8dd9f4dcab5826edbef4b7d477b81ac995253c6258844579a54243422b73446f6fb8653b979";
      name = "appleskin-fabric-mc1.20.1-2.5.1.jar";
    })
    # areas-1.20.1-6.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/NWvsqJ2Z/versions/z8wdbzwT/areas-1.20.1-6.1.jar";
      sha512 = "51d385f5bf8a7e37fb42f18d58c4b826084babecdce1b3dff21a39fc772983657ce36663a02f241d2746d203fc76c45772c699c9f5afef5b1dd3ee04e3161065";
      name = "areas-1.20.1-6.1.jar";
    })
    # athena-fabric-1.20.1-3.1.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/b1ZV3DIJ/versions/mXJWSwbJ/athena-fabric-1.20.1-3.1.2.jar";
      sha512 = "e55d49348a9d944bbd19390c64a4f42a1375eaaf0cbd4d69b4f523e441d9d23ce9498c912db724260cde32a43b776832cb867161e0989995d974de7e19e12389";
      name = "athena-fabric-1.20.1-3.1.2.jar";
    })
    # balm-fabric-1.20.1-7.3.37.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/MBAkmtvl/versions/qCk04klC/balm-fabric-1.20.1-7.3.37.jar";
      sha512 = "2fddc3053091ec9e9939f873f01a06752698adf56b0405df17c13e1f6359daa009dc8e194bb9591b172cc013900b9891b52993b779efb338b5d977b4099ae2da";
      name = "balm-fabric-1.20.1-7.3.37.jar";
    })
    # bettercombat-fabric-1.9.0+1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/5sy6g3kz/versions/OtwNg4r4/bettercombat-fabric-1.9.0%2B1.20.1.jar";
      sha512 = "477b53b13620c003dbf3da4c8facf9e5df81b101c72137aaee01a16e53b7be0bedc354d1d6e2039c40fe82a53cc92a324995d418cd6b8d6301ad02f6ad110717";
      name = "bettercombat-fabric-1.9.0+1.20.1.jar";
    })
    # BiomesOPlenty-fabric-1.20.1-19.0.0.96.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/HXF82T3G/versions/eZaag2ca/BiomesOPlenty-fabric-1.20.1-19.0.0.96.jar";
      sha512 = "0d8af03235f92465c158a38f4a3497658895d3f6cbb761b7c1eaf549d86622a2b3214d32d92de30b1ed86fa55085fd78c6f03cae289e51f09cd8701fda8b4619";
      name = "BiomesOPlenty-fabric-1.20.1-19.0.0.96.jar";
    })
    # blanket-client-tweaks-1.1.4.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/gxpkKtVH/versions/Bugxmes1/blanket-client-tweaks-1.1.4.jar";
      sha512 = "2643e683610d4a81c7c8ca19ed6ce995cb8395fdf900dcd4a850b427634e15e4c7d189676e2d98fe4e678fa725c23210a7f528a986ea7c7eba3f7d534b791a86";
      name = "blanket-client-tweaks-1.1.4.jar";
    })
    # c2me-fabric-mc1.20.1-0.2.0+alpha.11.16.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/VSNURh3q/versions/s4WOiNtz/c2me-fabric-mc1.20.1-0.2.0%2Balpha.11.16.jar";
      sha512 = "359c715fd6a0464192d36b4d9dbb7927776eaae498f0cab939b49740fc724bda83aaf4f069f395dc5975d1e82762ee3b602111d9375eb27ab6f5360c4b17f2ff";
      name = "c2me-fabric-mc1.20.1-0.2.0+alpha.11.16.jar";
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
    # cloth-config-11.1.136-fabric.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/9s6osm5g/versions/2xQdCMyG/cloth-config-11.1.136-fabric.jar";
      sha512 = "2da85c071c854223cc30c8e46794391b77e53f28ecdbbde59dc83b3dbbdfc74be9e68da9ed464e7f98b4361033899ba4f681ebff1f35edc2c60e599a59796f1c";
      name = "cloth-config-11.1.136-fabric.jar";
    })
    # Clumps-fabric-1.20.1-12.0.0.4.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Wnxd13zP/versions/hefSwtn6/Clumps-fabric-1.20.1-12.0.0.4.jar";
      sha512 = "2235d29b1239d5526035bffd547d35fe33b9e737d3e75cd341f6689d9cd834d0a7dc03ed80748772162cd9595ba08e7a0ab51221bc145a8fd979d596c3967544";
      name = "Clumps-fabric-1.20.1-12.0.0.4.jar";
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
    # combatroll-fabric-1.3.3+1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/wGKYL7st/versions/FyOp03FS/combatroll-fabric-1.3.3%2B1.20.1.jar";
      sha512 = "6703c3b2b6e6b063102b50e65aa4be29bc4b46f7830cf3a396bfb5fac78c3a29d1bcfe2b796fbe2c79f948bdb098931d076bee58f5ce5ff37a40ad699544ff04";
      name = "combatroll-fabric-1.3.3+1.20.1.jar";
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
    # cullleaves-fabric-4.1.1+1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/GNxdLCoP/versions/jpXb8qLT/cullleaves-fabric-4.1.1%2B1.20.1.jar";
      sha512 = "df0375099ab14fbfa2805f0f791728532ae31c21e7cc2d0037e94edddedf6abd8733060a7649eeda5875e7c947d22fd3acfacb63f6398d0ca7f75e57c98bd20a";
      name = "cullleaves-fabric-4.1.1+1.20.1.jar";
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
    # dynamic-fps-3.9.5+minecraft-1.20.0-fabric.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/LQ3K71Q1/versions/D9mrJwm0/dynamic-fps-3.9.5%2Bminecraft-1.20.0-fabric.jar";
      sha512 = "8f6769b6ae3736e2481f0b4caea385ad6656b60b2493a1a746a3f0678e976494f7a0488ac4baa80531a38e8d64b1a61654ee97c238dc9b0e12347bdc6623520e";
      name = "dynamic-fps-3.9.5+minecraft-1.20.0-fabric.jar";
    })
    # easyelytratakeoff-1.20.1-4.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/3hqwGCUB/versions/JBhBlmby/easyelytratakeoff-1.20.1-4.5.jar";
      sha512 = "21490ad2524bfd094fa21ebc14c12e943a77bb90fa384ded24a83ecd40c0c579d85635b1e45a27bb38ab450279268cdb09f77d6325203f38e580775e5e5bbe28";
      name = "easyelytratakeoff-1.20.1-4.5.jar";
    })
    # eating-animation-1.20+1.9.61.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/rUgZvGzi/versions/AqXSvu6M/eating-animation-1.20%2B1.9.61.jar";
      sha512 = "7470cd63b49cd797a21b30fefe11bd53e419ca8ed0eb01f498b801e83222685bbe853e7323f2e310874a3619628fece48ec69ea53cd391dd97a139c64225d077";
      name = "eating-animation-1.20+1.9.61.jar";
    })
    # enhancedblockentities-0.9+1.20.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/OVuFYfre/versions/i3v1Skck/enhancedblockentities-0.9%2B1.20.jar";
      sha512 = "7e8b402fd25efd396bc7f0f25a663808ae9890accc227850c454dfcdc975657f22afceb15878e781485622434a6f6d60aff2a60264aa4425edd52ebe052a0de5";
      name = "enhancedblockentities-0.9+1.20.jar";
    })
    # edibles-1.20.1-4.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Rjl8pCZ9/versions/CvCMY635/edibles-1.20.1-4.5.jar";
      sha512 = "cf86aa75b1f79b64ee392c2af23ce7b4da7c50046acc6b10e8c63836f642940feef784f65924084ecaaf7abe95c84cb6084dd6e2e906a37ce0c850973f7ee85f";
      name = "edibles-1.20.1-4.5.jar";
    })
    # entityculling-fabric-1.9.4-mc1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/NNAgCjsB/versions/Pzx7Sq6t/entityculling-fabric-1.9.4-mc1.20.1.jar";
      sha512 = "ad52e9fba14217af2b2ae73ad739dfe0351ecf60597510bdda58922e5e6455fd03c16441b37a7ffe5b379e9e509bf47a8200d1600346e96324875e5526e5acfb";
      name = "entityculling-fabric-1.9.4-mc1.20.1.jar";
    })
    # fabric-api-0.92.6+1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/UapVHwiP/fabric-api-0.92.6%2B1.20.1.jar";
      sha512 = "2bd2ed0cee22305b7ff49597c103a57c8fbe5f64be54a906796d48b589862626c951ff4cbf5cb1ed764a4d6479d69c3077594e693b7a291240eeea2bb3132b0c";
      name = "fabric-api-0.92.6+1.20.1.jar";
    })
    # fastercrouching-1.20.1-2.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/lgEczyrc/versions/W5h7AXga/fastercrouching-1.20.1-2.6.jar";
      sha512 = "ba21ef9dd423b0e1e088928a56ea1b0a0095b21383a45a997b8a494c464d8dbfcb8dc1e58d2e98f7ce5d47426429d72dbfe1de88d83d0e82cb60fe254aec68f7";
      name = "fastercrouching-1.20.1-2.6.jar";
    })
    # ferritecore-6.0.1-fabric.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/uXXizFIs/versions/unerR5MN/ferritecore-6.0.1-fabric.jar";
      sha512 = "9b7dc686bfa7937815d88c7bbc6908857cd6646b05e7a96ddbdcada328a385bd4ba056532cd1d7df9d2d7f4265fd48bd49ff683f217f6d4e817177b87f6bc457";
      name = "ferritecore-6.0.1-fabric.jar";
    })
    # geckolib-fabric-1.20.1-4.8.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/8BmcQJ2H/versions/AXhbVyuq/geckolib-fabric-1.20.1-4.8.2.jar";
      sha512 = "cf0f40b02ce712610984c486ed6c7fa0c46f5926da0f8a4d329622dfaadf96a90bd1c2f9afdfc08082a66fb6e9dbf4d6853a9405f16c856bf0b55c62efcbb0a6";
      name = "geckolib-fabric-1.20.1-4.8.2.jar";
    })
    # GlitchCore-fabric-1.20.1-0.0.1.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/s3dmwKy5/versions/25HLOiOl/GlitchCore-fabric-1.20.1-0.0.1.1.jar";
      sha512 = "6aaf011fd04da2f2839da8e037add942588676385906d8ddad2927ca88414a37463f1b2e2ee2209a87cda8d2af9448a29e55e86ba2d94e857e46d28545ea7bbd";
      name = "GlitchCore-fabric-1.20.1-0.0.1.1.jar";
    })
    # handcrafted-fabric-1.20.1-3.0.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/pJmCFF0p/versions/NRw0CDAc/handcrafted-fabric-1.20.1-3.0.6.jar";
      sha512 = "92c3b47c635196d0991831ce64e2c47bd9d666ee6213bbba87b8f0214cccbba626a564ad130ec0336e94936568dce462d1ff6ca726a81134518795709632602e";
      name = "handcrafted-fabric-1.20.1-3.0.6.jar";
    })
    # healingcampfire-1.20.1-6.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/kOuPUitF/versions/olxRjKsI/healingcampfire-1.20.1-6.2.jar";
      sha512 = "141603dc3ab64744dbd1eef380b386dfcf606230186185f8d5cb98ca44034aa9d774820ab81ff273ec30e417afcf6d733768e98d6cfe120fe840a0c375e1f0e3";
      name = "healingcampfire-1.20.1-6.2.jar";
    })
    # ImmediatelyFast-Fabric-1.5.3+1.20.4.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/5ZwdcRci/versions/AIFWhP2u/ImmediatelyFast-Fabric-1.5.3%2B1.20.4.jar";
      sha512 = "abc9ab8ce9c688479d8006025c6268c509be10c0e1b3a86bd54c0665d8aecbf6222105055067cb815059dc62aa58dd956e27b89772124a4d82c96fcbac236d1c";
      name = "ImmediatelyFast-Fabric-1.5.3+1.20.4.jar";
    })
    # infinitetrading-1.20.1-4.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/U3eoZT3o/versions/DkRq9YKI/infinitetrading-1.20.1-4.6.jar";
      sha512 = "db19f120498b3cbe955e7eea4c76cbd6c3c243f359dc03ab151cd57d6bf49e529e4f7b8882530dc1a79ee2dca956465175ccddef2ac3d24d5ad810e309bdae7d";
      name = "infinitetrading-1.20.1-4.6.jar";
    })
    # inventorymending-1.20.1-1.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/y6Ryy40D/versions/ryxQwkdr/inventorymending-1.20.1-1.2.jar";
      sha512 = "e9762be33f9dc1ae04251dbefcb41e6a487c8fbce59f35cdf19804a9591260b07aead634dbd6be8e989fc4e8123448bb4980a8b651ec57130cf4a1d7b6a38079";
      name = "inventorymending-1.20.1-1.2.jar";
    })
    # InventoryProfilesNext-fabric-1.20-1.10.19.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/O7RBXm3n/versions/KV3ANetv/InventoryProfilesNext-fabric-1.20-1.10.19.jar";
      sha512 = "a1af43eca75aebe0be27772742ce0d02b283b3904b9c4a650fd616165e63532ba4f67cab72e9227e8399fc8ee9302fdbf17587c32e0bef73970aa20a8d4d0b21";
      name = "InventoryProfilesNext-fabric-1.20-1.10.19.jar";
    })
    # inventorytotem-1.20.1-3.4.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/yQj7xqEM/versions/FdstVlDW/inventorytotem-1.20.1-3.4.jar";
      sha512 = "1ade16e67b8bf42d8479312763ebf44ffdbc2fb257eecc157679fc2aa7226b8d79f068c01d7af262dde66d489c261ede99613915b45e59ce2699548cbd377cd7";
      name = "inventorytotem-1.20.1-3.4.jar";
    })
    # iris-1.7.6+mc1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/YL57xq9U/versions/s5eFLITc/iris-1.7.6%2Bmc1.20.1.jar";
      sha512 = "f1337b0441c31269bd3bfcb28647d521326a83e73128c1ac8d065615f8a5a4ca1e8c96a468b356584236ece5b164ec8d8a52b1878064f4e391ecf4f32885e301";
      name = "iris-1.7.6+mc1.20.1.jar";
    })
    # Highlighter-1.20.1-fabric-1.1.9.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/cVNW5lr6/versions/vyEyvJgV/Highlighter-1.20.1-fabric-1.1.9.jar";
      sha512 = "3f55e9c3a8a35e2aa0234e8cf6a34dc1303bf3fa2b9c2fc2b7f6cd86153017bc901d164d8cf7f413959422647e627ee36e2cc34a85be56d085b0807afefe1a62";
      name = "Highlighter-1.20.1-fabric-1.1.9.jar";
    })
    # jei-1.20.1-fabric-15.20.0.129.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/u6dRKJwZ/versions/wbPLxn0B/jei-1.20.1-fabric-15.20.0.129.jar";
      sha512 = "c236643fec7dab72a68d772c0739bc95e2b8b59dbe082b68cafac5457bfd0e87f611fef9b7e973dbe377d6dd76b538327da2a595183b2a3808cc5fe0006cef0f";
      name = "jei-1.20.1-fabric-15.20.0.129.jar";
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
    # lambdabettergrass-2.0.3+1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/2Uev7LdA/versions/eTxu3nyw/lambdabettergrass-2.0.3%2B1.20.1.jar";
      sha512 = "4a00e4a8f8ce95a16f1366a79d58a6514bb0611e7dc55d69b637c4729a8e77e2121f28d0349f05374b17f5ffcfa7d289d306f4181838490e9550cc686ce2ee28";
      name = "lambdabettergrass-2.0.3+1.20.1.jar";
    })
    # lambdynamiclights-4.4.0+1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/yBW8D80W/versions/AQfTnYyJ/lambdynamiclights-4.4.0%2B1.20.1.jar";
      sha512 = "65f297e32ba3a72537b22730dfbe8dac9ce1ba33e62c2ddf85302b8a5131dd1fe92cca151673599c0b6adeb4ec5bd254f2cfdde66c3ca909f08e9319ebfacb56";
      name = "lambdynamiclights-4.4.0+1.20.1.jar";
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
    # lovely_snails-1.1.5+1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/hBVVhStr/versions/n1JQ3yYD/lovely_snails-1.1.5%2B1.20.1.jar";
      sha512 = "6475565b349b555accc426a6b0ccf62b990d38f35bb8e67745567643efc9530f3dea1bd11c5eb7d13b6c80f660f3d74ecac07c2b992ebbadae97f7237bff1f26";
      name = "lovely_snails-1.1.5+1.20.1.jar";
    })
    # midnightcontrols-1.9.4+1.20.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/bXX9h73M/versions/xHOdr9un/midnightcontrols-1.9.4%2B1.20.jar";
      sha512 = "722f127d91eeaa42494ffae581536d563a99fa0075b5a92ccf27b31a4e25ce86a2a89e28f9b4084281a0e67b1816f1d7656010ca863cd8a08c195b1ac69d0fd6";
      name = "midnightcontrols-1.9.4+1.20.jar";
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
    # modmenu-7.2.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/mOgUt4GM/versions/lEkperf6/modmenu-7.2.2.jar";
      sha512 = "9a7837e04bb34376611b207a3b20e5fe1c82a4822b42929d5b410809ec4b88ff3cac8821c4568f880775bafa3c079dfc7800f8471356a4046248b12607e855eb";
      name = "modmenu-7.2.2.jar";
    })
    # moreculling-1.20.1-0.24.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/51shyZVL/versions/4sFiGeSt/moreculling-1.20.1-0.24.2.jar";
      sha512 = "5787537c367342e7b82549f86823ecc389e01a80f8c3e31853dea68150f0796c2c8df831d055c4efd8d4e62f40a803d24ba2acec3447cd0e8137f0a53d7118e1";
      name = "moreculling-1.20.1-0.24.2.jar";
    })
    # MouseTweaks-fabric-mc1.20-2.26.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/aC3cM3Vq/versions/mjuG4AYd/MouseTweaks-fabric-mc1.20-2.26.jar";
      sha512 = "d0faf200dda358efddad2d2809f646023f4dd06254572369e07f3bf33cb6941f0fcdb02db4675b30b4f3bd542cbf6196e135680ba91a2b74c2b071f34978e2d5";
      name = "MouseTweaks-fabric-mc1.20-2.26.jar";
    })
    # nametagtweaks-1.20.1-4.0.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/LrLZEnPl/versions/xFDnAS8R/nametagtweaks-1.20.1-4.0.jar";
      sha512 = "1ff3ecc2ca7968b9a6f559d7979503ba571f79c9f34bebe17333b83671b4855a87775f36f7aaa151d271a5a1647cbe8131d0d4fad425211a6ad326b4f62c34f8";
      name = "nametagtweaks-1.20.1-4.0.jar";
    })
    # NaturesCompass-1.20.1-2.2.3-fabric.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/fPetb5Kh/versions/NovIXDxY/NaturesCompass-1.20.1-2.2.3-fabric.jar";
      sha512 = "b57dabd55010b598a66fe13644380c452ea75d4717b6acb7cd4f7718d6d535920cf7e216491bde427066d7e68dfaee5ef7226b7c8322b4f8771cf0dc9416e56e";
      name = "NaturesCompass-1.20.1-2.2.3-fabric.jar";
    })
    # nohostilesaroundcampfire-1.20.1-7.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/EJqeyaVz/versions/iNnx7a2g/nohostilesaroundcampfire-1.20.1-7.2.jar";
      sha512 = "1eae3222ec664b0d86567bff76e84736564bd294ceb444cf7e8027a13a7f2136d81704c3c1876b3e321daff82d978bfa75ac04066925e0a21db9d9d4ae9b41f7";
      name = "nohostilesaroundcampfire-1.20.1-7.2.jar";
    })
    # notenoughanimations-fabric-1.11.1-mc1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/MPCX6s5C/versions/AEVtLh4I/notenoughanimations-fabric-1.11.1-mc1.20.1.jar";
      sha512 = "cf6ee6f1cd1c4d2ae213bffd86bafeb6e9de28400673dfff5d33a6f6c3e47ef4897802da8de8063193f01fb51c7aa2a21f1629a91be1c990d1c9c26fccc4d47a";
      name = "notenoughanimations-fabric-1.11.1-mc1.20.1.jar";
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
    # piglinnames-1.20.1-1.3.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/54plduvG/versions/H6wd5Jo8/piglinnames-1.20.1-1.3.jar";
      sha512 = "d09e64a3af5859688b43c19c25bc7a45af2b151f2130bc2a2dde5885de59323503e46b8c8f10bcaf8f36df694c1d871d0b8a6188b1c1b7d904459ff5e130b5f1";
      name = "piglinnames-1.20.1-1.3.jar";
    })
    # PresenceFootsteps-1.10.1+1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/rcTfTZr3/versions/k0t6DSmw/PresenceFootsteps-1.10.1%2B1.20.1.jar";
      sha512 = "c306f96496aadc30abcaac0bd35e22f870e974fe532eaf1f2b66bfd5e7e5e7f6276d58b393bcd6521e8ea74b38a52b54246e2cd0344d9acf8ed4cb233f9a1e1d";
      name = "PresenceFootsteps-1.10.1+1.20.1.jar";
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
    # SereneSeasons-fabric-1.20.1-9.1.0.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/e0bNACJD/versions/c1BdjabH/SereneSeasons-fabric-1.20.1-9.1.0.2.jar";
      sha512 = "ea63dae236cd9d259566ab7ad0b6edeeca3ed9818edcb61079c4e85b8ab6ed731a88b978a0724f61a53e841d70ca4a23c599dc31bbd9f57cfd6ade5675256808";
      name = "SereneSeasons-fabric-1.20.1-9.1.0.2.jar";
    })
    # shulkerboxtooltip-fabric-4.0.4+1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/2M01OLQq/versions/gVxjsEiQ/shulkerboxtooltip-fabric-4.0.4%2B1.20.1.jar";
      sha512 = "65cdc8b565e5a7f9a855dd35c7c4b20daae0c6a5822e9a32dabd0f8fd4df6353c9fbd9d1437b83c6f7824e1c65ce466a82f70a7b7ef007bd54afa63718037043";
      name = "shulkerboxtooltip-fabric-4.0.4+1.20.1.jar";
    })
    # shulkerdropstwo-1.20.1-3.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/UjXIyw47/versions/89tfEaAo/shulkerdropstwo-1.20.1-3.5.jar";
      sha512 = "072d5d7c11fc7498572e873ea993a94c277feee1268de29c41b242098286be0494a9648528e62148bc091c6072f19b4ebef8a0ec82578fed38a2bc17d5062c5d";
      name = "shulkerdropstwo-1.20.1-3.5.jar";
    })
    # silkiertouch-1.20.1-1.0.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/dUaXeoyM/versions/QzG6pi6d/silkiertouch-1.20.1-1.0.jar";
      sha512 = "af3a64d8e44537484cdee7980f8db58e95752b29e3d552a69a22a87980aa7a1caf8824539a1eb46c7f20969d2982a7f130a6ec22f6fc7c3ff5d6ba7f1545e066";
      name = "silkiertouch-1.20.1-1.0.jar";
    })
    # voicechat-fabric-1.20.1-2.6.10.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/9eGKb6K1/versions/EU71LKN3/voicechat-fabric-1.20.1-2.6.10.jar";
      sha512 = "ba32698dab4399ecf543df2d7aba1f6e9dd46e769842b238b15396ca885aaf0cdd31c2e9b68faadb2ebc21b8c5455b5bea00b4604fa3d6c9b929e670000a8949";
      name = "voicechat-fabric-1.20.1-2.6.10.jar";
    })
    # smallernetherportals-1.20.1-3.9.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/fYAofsi6/versions/AKAgpUev/smallernetherportals-1.20.1-3.9.jar";
      sha512 = "9ecae52cc42fe3edc1a45b157d495cddf867975d1f63a6c3aa65e732eeac40ac5bae3e3d1269cd342fe077e548e67cd7b9f05a1a3e760447162f192c4cfca91b";
      name = "smallernetherportals-1.20.1-3.9.jar";
    })
    # sodium-extra-0.5.9+mc1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/PtjYWJkn/versions/mDbF0LZT/sodium-extra-0.5.9%2Bmc1.20.1.jar";
      sha512 = "c47b765f8e062ca7e3471fe5e74aabdf56160d5b67b64dfcca8c177ede914715097ae4e94defe2a6b02bf86ccba1e7bf471073c71bb126e51adf21e54c5864e3";
      name = "sodium-extra-0.5.9+mc1.20.1.jar";
    })
    # sodium-fabric-0.5.13+mc1.20.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/AANobbMI/versions/OihdIimA/sodium-fabric-0.5.13%2Bmc1.20.1.jar";
      sha512 = "81c64f9c2d3402dfa43ee54d8f5a054f5243bfb08984e3addcab9fe885073c79c43c1c8c41e8f30b625d26a656f82a8e5f370bbbbf222ff1c08f4b324edb7ea4";
      name = "sodium-fabric-0.5.13+mc1.20.1.jar";
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
    # TerraBlender-fabric-1.20.1-3.0.1.10.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/kkmrDlKT/versions/J1S3aA8i/TerraBlender-fabric-1.20.1-3.0.1.10.jar";
      sha512 = "a2d5edbe9df43185e9c83ab426cbcda4b1d0537d9ede8be630d6d650e04d5decf574ef59cbc163913255b57784fa906d26557471fc698e0f27ceee2a1ec41ed9";
      name = "TerraBlender-fabric-1.20.1-3.0.1.10.jar";
    })
    # tntbreaksbedrock-1.20.1-3.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/eU2O6Xp1/versions/2loAM9df/tntbreaksbedrock-1.20.1-3.5.jar";
      sha512 = "eaad5e9274e971479af5c638beadb37ac96938a9b8eca41074fd196f85ae775cb38b2e9305144849913d7fa80087858cdda14539c9b965ddfdc425ada68405e6";
      name = "tntbreaksbedrock-1.20.1-3.5.jar";
    })
    # travelersbackpack-fabric-1.20.1-9.1.43.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/rlloIFEV/versions/hvbhRvQa/travelersbackpack-fabric-1.20.1-9.1.43.jar";
      sha512 = "a54ae9bf255fade2bbd2e8efa403bd185714cb91df81a0e36c88fed664c66f5db3e6d52aa827b89a11c9c83f90799b9c23a65e074a19623d69e891e838881374";
      name = "travelersbackpack-fabric-1.20.1-9.1.43.jar";
    })
    # TravelersTitles-1.20-Fabric-4.0.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/JtifUr64/versions/MbifZGB0/TravelersTitles-1.20-Fabric-4.0.2.jar";
      sha512 = "a8af88107664482f907e5e797156f677e79f96009b834a77f38c184cc651b88db5adac2f4edd8c6945a199157eedd9a366774f7a52458e8286fdbb492d4d8787";
      name = "TravelersTitles-1.20-Fabric-4.0.2.jar";
    })
    # treeharvester-1.20.1-9.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/abooMhox/versions/EQYmDYvI/treeharvester-1.20.1-9.1.jar";
      sha512 = "eab24be8a6b75ed03dcd9b324acb6f79145839836faa9829546a663e2cc782e4dd49323a9300e832105b02e44dd642b3994d6ad49c6dcc485d6f9f14136cdc15";
      name = "treeharvester-1.20.1-9.1.jar";
    })
    # trinkets-3.7.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/5aaWibi9/versions/AHxQGtuC/trinkets-3.7.2.jar";
      sha512 = "bedf97c87c5e556416410267108ad358b32806448be24ef8ae1a79ac63b78b48b9c851c00c845b8aedfc7805601385420716b9e65326fdab21340e8ba3cc4274";
      name = "trinkets-3.7.2.jar";
    })
    # undergroundbeacons-1.20.1-1.0.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/SMC0xf5E/versions/HLQ2SIMB/undergroundbeacons-1.20.1-1.0.jar";
      sha512 = "237a3165466d96c5d81b2f3680a11fcf64611e3ca7fe890d77de15a6b0eea56f4a57f5b4fb31b888db36cd3da8a68d3cc07587ce92fe73e58d95b1b5095448a0";
      name = "undergroundbeacons-1.20.1-1.0.jar";
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
    # visuality-0.7.1+1.20.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/rI0hvYcd/versions/uhvQD6Ny/visuality-0.7.1%2B1.20.jar";
      sha512 = "854148cde0cee5a10192af246aae8dd2267b36dfc46bfea5cb4550393acf67523909e22ce0bf1827607ee27c7a32878119435127802499f68e4b1768446fe9a8";
      name = "visuality-0.7.1+1.20.jar";
    })
    # waystones-fabric-1.20.1-14.1.17.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/LOpKHB2A/versions/USFFIy4C/waystones-fabric-1.20.1-14.1.17.jar";
      sha512 = "9e30cee4fbfebd87632a9979db95db557010540acdd4dfc967c538d818cc613c62fb53f1e4b061485424f070f9eac5eb6f89c5addcac735abdbd4242a38932a0";
      name = "waystones-fabric-1.20.1-14.1.17.jar";
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
    # YungsApi-1.20-Fabric-4.0.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Ua7DFN59/versions/lscV1N5k/YungsApi-1.20-Fabric-4.0.6.jar";
      sha512 = "90fea70f21cd09bdeefe9cb6bd23677595b32156b1b8053611449504ba84a21ee1e13e5a620851299090ce989f41b97b9b4bdc98def1ccecb33115e19553c64e";
      name = "YungsApi-1.20-Fabric-4.0.6.jar";
    })
    # YungsBetterCaves-1.20.1-Fabric-2.0.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Dfu00ggU/versions/bsjRT669/YungsBetterCaves-1.20.1-Fabric-2.0.5.jar";
      sha512 = "db01f5c133c62c23f2a92ab83e19ea81682ff88b9625374865ad4f465fb1496bd6b11d3c3453fab1601765400d2a914150c2fb018b63e835d5358971bf5fafa3";
      name = "YungsBetterCaves-1.20.1-Fabric-2.0.5.jar";
    })
    # YungsBetterDesertTemples-1.20-Fabric-3.0.3.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/XNlO7sBv/versions/1Z9HNWpj/YungsBetterDesertTemples-1.20-Fabric-3.0.3.jar";
      sha512 = "29839615e042435b0fdacab2b97524a6689190692a289c25e305dbaec34764f38e70c65cfd77b49ac0dcc549281b61cfe244edc62809082e39db54990ef84cbf";
      name = "YungsBetterDesertTemples-1.20-Fabric-3.0.3.jar";
    })
    # YungsBetterDungeons-1.20-Fabric-4.0.4.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/o1C1Dkj5/versions/nidyvq2m/YungsBetterDungeons-1.20-Fabric-4.0.4.jar";
      sha512 = "02ee00641aea2e80806923c1d97a366b82eb6d6e1d749fc8fb4eeddeddea718c08f5a87ba5189427f747801b899abe5a6138a260c7e7f949e5e69b4065ac5464";
      name = "YungsBetterDungeons-1.20-Fabric-4.0.4.jar";
    })
    # YungsBetterEndIsland-1.20-Fabric-2.0.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/2BwBOmBQ/versions/qJTsmyiE/YungsBetterEndIsland-1.20-Fabric-2.0.6.jar";
      sha512 = "cb63d9cdd69f955ed8044aec6f03aedbf76fdb53fd97826b254b68e3559941df301b714260505d165c58c276aa7ea7c11c2fada7509cb731f10b1815d5633b87";
      name = "YungsBetterEndIsland-1.20-Fabric-2.0.6.jar";
    })
    # YungsBetterJungleTemples-1.20-Fabric-2.0.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/z9Ve58Ih/versions/6LPrzuB0/YungsBetterJungleTemples-1.20-Fabric-2.0.5.jar";
      sha512 = "ea08ade714376f48cabdddd2e4b7376fc5cc5947e3911583ba4e182ab22c1335c884043441725cde21fb6e84402d17c43f509ade339d46a1a1db40f0e77ee81a";
      name = "YungsBetterJungleTemples-1.20-Fabric-2.0.5.jar";
    })
    # YungsBetterMineshafts-1.20-Fabric-4.0.4.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/HjmxVlSr/versions/qLnQnqXS/YungsBetterMineshafts-1.20-Fabric-4.0.4.jar";
      sha512 = "82d6e361ef403471beaaf2fa86964af541df167da56f53b820e5abfac693f63dd5d6c0aafbc9e9baa947b42a57c79f069ed6ede55e680a2523d2ca7f2e538b13";
      name = "YungsBetterMineshafts-1.20-Fabric-4.0.4.jar";
    })
    # YungsBetterNetherFortresses-1.20-Fabric-2.0.6.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Z2mXHnxP/versions/FL88RLRu/YungsBetterNetherFortresses-1.20-Fabric-2.0.6.jar";
      sha512 = "a752f0dea20fa86e6d3a4f87d180af706b2ad5e3d434185aaa624692fc55329a2e2e410e67f843ec982e7b90ae63565b4aed43adbee6c50ded403ef50d91d7fd";
      name = "YungsBetterNetherFortresses-1.20-Fabric-2.0.6.jar";
    })
    # YungsBetterOceanMonuments-1.20-Fabric-3.0.4.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/3dT9sgt4/versions/4c00pjbt/YungsBetterOceanMonuments-1.20-Fabric-3.0.4.jar";
      sha512 = "b050f94b70628f9cb64afe1d184b3fd5eee4a7d556ff81b05dd90e954484c415b24b235a8471085cbba2e28a1123e49de9a16e6e7bc52da585db81762562f186";
      name = "YungsBetterOceanMonuments-1.20-Fabric-3.0.4.jar";
    })
    # YungsBetterStrongholds-1.20-Fabric-4.0.3.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/kidLKymU/versions/yV6hn0bB/YungsBetterStrongholds-1.20-Fabric-4.0.3.jar";
      sha512 = "e70c8daa91e88d8af97e99201264c9646c82a8cf1966b87ca1e53b591e7f1ed3cee2f8875dbe88f9b58e2a7d151fded34896bb4bd23f33f2bfef4c590fbba850";
      name = "YungsBetterStrongholds-1.20-Fabric-4.0.3.jar";
    })
    # YungsBetterWitchHuts-1.20-Fabric-3.0.3.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/t5FRdP87/versions/lYpHN3iF/YungsBetterWitchHuts-1.20-Fabric-3.0.3.jar";
      sha512 = "4182c4b580ac0446968d28561088807a5fc96c4ad792401bf918b2e693f7eb343237f2887d63121469af8a120c4ccc8c84d7add731ea1a45cb429f49092bd6ac";
      name = "YungsBetterWitchHuts-1.20-Fabric-3.0.3.jar";
    })
    # YungsBridges-1.20-Fabric-4.0.3.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Ht4BfYp6/versions/hvfjXu8d/YungsBridges-1.20-Fabric-4.0.3.jar";
      sha512 = "3cdd923781fe6446466670bce8132bbc0a1ee27ae9a76bb25bf0010c0e79c821ce1dc606405e3ffa00f22d92629aa1cd7cc680a17c98dfcf338166372b85dab1";
      name = "YungsBridges-1.20-Fabric-4.0.3.jar";
    })
    # YungsCaveBiomes-1.20.1-Fabric-2.0.5.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/cs7iGVq1/versions/8h469FpE/YungsCaveBiomes-1.20.1-Fabric-2.0.5.jar";
      sha512 = "02e689eb98ddd8390f1853751891addb4e0888ce35682ab12e565dba842d999d494284ac7423783ab10c333d1888284ca30a7e21d358e5a5002b1bb8086af37d";
      name = "YungsCaveBiomes-1.20.1-Fabric-2.0.5.jar";
    })
    # YungsExtras-1.20-Fabric-4.0.3.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/ZYgyPyfq/versions/pfVTUz1L/YungsExtras-1.20-Fabric-4.0.3.jar";
      sha512 = "9fb06e136b12548ca9cb82d5d1035d760b74c7acded4b0d01ea29fb1e47c4666e1f289e6ce3e0c77510bc4bd10a64946e17633f99f60b5424a535d8d88025412";
      name = "YungsExtras-1.20-Fabric-4.0.3.jar";
    })
    # YungsMenuTweaks-1.20.1-Fabric-1.0.2.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Hcy2DFKF/versions/QRV0K267/YungsMenuTweaks-1.20.1-Fabric-1.0.2.jar";
      sha512 = "dabd072d735b802a1e62f62e8ce9b3276c931a16f6d4e160f77f31d511ebc368fa9a3580a70df8438739f86ad606e1d4e16b687b0953e5917bf9814ce5a8c930";
      name = "YungsMenuTweaks-1.20.1-Fabric-1.0.2.jar";
    })
    # zombieawareness-fabric-1.20.1-1.13.1.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/mMTOWOaA/versions/nkFcvMt7/zombieawareness-fabric-1.20.1-1.13.1.jar";
      sha512 = "3f1a04fe18d8de6bae187b4af9f424dc94e0cf7877822035de52b234ed15ad8c815c0171aa9a718e86f8a4c0364818bf8cbb6016afe016445d5c3d98f60900e9";
      name = "zombieawareness-fabric-1.20.1-1.13.1.jar";
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
