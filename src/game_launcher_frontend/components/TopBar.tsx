import React from "react";
import { useTranslation } from "react-i18next";
import { NavLink, useNavigate } from "react-router-dom";
import { Disclosure } from "@headlessui/react";
import { Bars3Icon, XMarkIcon } from "@heroicons/react/24/solid";
import { useScrollPosition } from "@todayweb/hooks";
import { useAuthContext } from "@/context/authContext";
import { useGlobalContext } from "@/context/globalContext";
import { useThemeContext } from "@/context/themeContext";
import { navPaths } from "@/shared";
import { cx } from "@/utils";
import SideBar from "./SideBar";
import ThemeSwitcher from "./ThemeSwitcher";
import Button from "./ui/Button";
import { useGetUserProfileDetail } from "@/api/profile";
import Loader from "./ui/Loader";
import toast from "react-hot-toast";
import "../styles/Terms.css";
import Space from "./ui/Space";

const TopBar = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const { isOpenNavSidebar, setIsOpenNavSidebar } = useGlobalContext();
  const { session, login, logout } = useAuthContext();
  const { theme } = useThemeContext();

  const scrollY = useScrollPosition();

  const openOrNotTop = (open: boolean) => scrollY > 0 || open;

  const principal = session?.address?.slice(0, 10);

  const paths = [
    {
      name: t("navigation.gaming_guilds"),
      path: navPaths.home
    },
    {
      name: t("navigation.launchpad"),
      path: navPaths.launchpad
    }
  ];

  const dev_tools = [
    {
      name: t("navigation.browse_games"),
      path: navPaths.browse_games,
    },
    {
      name: t("navigation.upload_games"),
      path: navPaths.upload_games,
    },
    {
      name: t("navigation.world_deployer"),
      path: navPaths.world_deployer
    },
    {
      name: t("navigation.manage_NFTs"),
      path: navPaths.manage_nfts,
    },
    {
      name: t("navigation.token_deployer"),
      path: navPaths.token_deployer,
    }
  ];

  const [selectedOption, setSelectedOption] = React.useState<string | null>(null);
  const [isDropdownOpen, setIsDropdownOpen] = React.useState(false);

  const { data: userProfile, isLoading } = useGetUserProfileDetail();

  const handleOptionClickLoggedIn = () => {
    setIsDropdownOpen(false);
  };

  const handleTosClick = () => {
    setIsOpenNavSidebar(false);
    toast.custom((t) => (
      <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
        <div className="w-3/4 rounded-3xl mb-7 p-0.5 gradient-bg mt-32 inline-block">
          <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
            <p className="text-2xl font-bold mt-4">Terms Of Service</p>
            <p className="c5 c3"><span className="c1"></span></p>
            <p className="c5 c3"><span className="c1"></span></p>
            <div className="overflow-y-auto h-80 px-20">
              <p className="c5"><span className="c8">Last Revised:</span><span className="c2">&nbsp;March 1, 2024</span></p>
              <p className="c5"><span className="c12"><br></br>Play3 Ltd (</span><span className="c8">&quot;BOOM DAO&quot;</span><span
                className="c12">, </span><span className="c8">&quot;we&quot;</span><span className="c12">, </span><span
                  className="c8">&quot;our&quot;</span><span className="c12">, or </span><span className="c8">&quot;us&quot;</span><span
                    className="c12">) offers BOOM DAO, a web3 gaming platform built on the Internet Computer Protocol (ICP). Play3
                  Ltd and BOOM DAO are used interchangeably in the following Terms of Services. Please read these Terms of
                  Service (herein the </span><span className="c8">&quot;Terms&quot;</span><span className="c2">) very
                    carefully.<br></br></span></p>
              <Space size="small" />
              <p className="c5"><span className="c12">These Terms are between you (</span><span className="c8">&quot;you&quot;</span><span
                className="c12">&nbsp;and </span><span className="c8">&quot;your&quot;</span><span className="c12">) and Play3 Ltd.
                  These Terms governs your use of the website located at </span><span className="c7"><a className="c11"
                    href="https://boomdao.xyz/">boomdao.xyz</a></span><span
                      className="c12">, </span><span className="c7"><a className="c11"
                        href="https://launcher.boomdao.xyz/"> launcher.boomdao.xyz</a></span><span
                          className="c12">, and any other site owned or operated by Play3 Ltd that links to these Terms (collectively the
                  &ldquo;Site&rdquo;), and all related tools, web applications, decentralized applications, smart contracts,
                  and APIs offered by Play3 Ltd (collectively, including the Site, the </span><span
                    className="c8">&quot;Platform&quot;</span><span className="c2">).<br></br></span></p>
              <Space size="small" />
              <h3 className="c5 h.cgqp1fsvgja4"><span className="c4">1. YOUR ACCEPTANCE OF THESE TERMS; ARBITRATION DISCLAIMER</span>
                <Space size="small" />
              </h3>
              <p className="c5"><span className="c2">BY CLICKING THE &ldquo;I ACCEPT&rdquo; BUTTON OR ANY SIMILAR ATTESTATION WHEN SUCH
                OPTION IS MADE AVAILABLE TO YOU, BY LINKING YOUR DIGITAL WALLET, OR BY OTHERWISE USING THE PLATFORM, YOU
                ACCEPT AND AGREE TO BE BOUND BY THESE TERMS EFFECTIVE AS OF THE DATE OF SUCH ACTION. YOU EXPRESSLY
                ACKNOWLEDGE AND REPRESENT THAT YOU HAVE CAREFULLY REVIEWED THESE TERMS AND FULLY UNDERSTAND THE RISKS, COSTS
                AND BENEFITS RELATED TO TRANSACTIONS MADE USING THE PLATFORM. IF YOU DO NOT AGREE WITH THESE TERMS, THEN YOU
                ARE EXPRESSLY PROHIBITED FROM USING THE PLATFORM.</span></p>
              <Space size="small" />
              <p className="c5"><span className="c2">The Platform is intended for users who are at least 18 years old. Persons under the
                age of 18 are not permitted to use or register for the Platform.</span></p>
              <Space size="small" />
              <p className="c5"><span className="c8 c15">PLEASE READ THE SECTION ENTITLED &ldquo;DISPUTE RESOLUTION&rdquo;
                CAREFULLY!</span><span className="c2">&nbsp;THESE TERMS CONTAIN AN ARBITRATION AGREEMENT IN SECTION 10 ENTITLED
                  &ldquo;DISPUTE RESOLUTION - ARBITRATION&rdquo; WHICH LIMITS OR MAY OTHERWISE AFFECT YOUR LEGAL RIGHTS,
                  INCLUDING YOUR RIGHT TO FILE A LAWSUIT IN COURT AND TO HAVE A JURY HEAR YOUR CLAIM AGAINST BOOM DAO. IF YOU
                  DO NOT WISH TO WAIVE RIGHTS AND SUBMIT TO ARBITRATION, YOU MUST CONTACT US WITHIN THIRTY (30) DAYS OF FIRST
                  USING THE PLATFORM AND INFORM US THAT YOU OPT-OUT OF SUCH CLASSName ACTION WAIVER AND/OR ARBITRATION
                  RIGHT.<br></br></span></p>
              <Space size="small" />
              <h3 className="c5 h.m4xypxxzghu2"><span className="c4">2. CHANGES TO TERMS</span></h3>
              <Space size="small" />
              <p className="c5"><span className="c2">We reserve the right, in our sole discretion, to make changes or modifications to
                these Terms at any time and for any reason. All changes are effective immediately when we post them. It is
                your responsibility to regularly check these Terms to stay informed of updates, as they are binding. We will
                indicate that these Terms have been updated by updating the &ldquo;Last Revised&rdquo; date at the top of
                these Terms. Your continued use of the Site following the posting of revised Terms means that you accept and
                agree to the changes.<br></br></span></p>
              <Space size="small" />
              <h3 className="c5 h.h3ncoztdgb73"><span className="c4">3. BOOM DAO PLATFORM</span></h3>
              <Space size="small" />
              <h4 className="c5 h.9sf6kdp1y5lh"><span className="c1">3.1 Platform</span></h4>
              <Space size="small" />
              <p className="c5"><span className="c2">The Platform at its core is an ecosystem for game development, content creation and
                interactive game play using blockchain technology and Digital Assets (as defined below). Games offered on
                the Platform and software built by third-party developers on the Platform, may be subject to additional
                terms. Please review all applicable terms with respect to any game or Digital Asset (as defined below) which
                will apply in addition to these Terms. </span></p>
              <Space size="small" />
              <h4 className="c5 h.eezc818xuz48"><span className="c1">3.2 Access and Use of the Platform</span></h4>
              <Space size="small" />
              <p className="c5"><span className="c2">You are hereby granted limited, revocable, non-exclusive, nontransferable,
                non-assignable, non-sublicensable access to and use of the Platform solely in accordance with the
                Documentation and these Terms. You shall not (a) except as expressly permitted under these Terms with
                respect to your owned NFTs, distribute, publicly perform, or publicly display any BOOM DAO Materials (as
                defined below), (b) modify or otherwise make any derivative uses of the Platform, or any portion thereof,
                (c) download (other than page caching) any portion of the Platform or BOOM DAO Materials, except as
                expressly permitted by us, or (d) use the Platform or BOOM DAO Materials other than for their intended
                purposes.</span></p>
              <p className="c5"><span className="c2">BOOM DAO shall have sole and complete control over, and reserves the right at any
                time to make any changes to, the configuration, appearance, content functionality, and scope of the
                Platform, including any BOOM DAO Materials. Notwithstanding anything contained in these Terms, we reserve
                the right, without notice and in our sole discretion, to impose limitations on, suspend, and/or terminate
                your right to access or use the Platform, in whole or in part, at any time and for any or no reason, and you
                acknowledge and agree that we shall have no liability or obligation to you in such event and that you shall
                not be entitled to a refund of any amounts that you have already paid to us, to the fullest extent permitted
                by applicable law.</span></p>
              <Space size="small" />
              <h4 className="c5 h.bakqqt1o8t7q"><span className="c1">3.3 Developer Generated Game</span></h4>
              <Space size="small" />
              <p className="c5"><span className="c12">The Platform enables users to develop their own game(</span><span
                className="c8">&ldquo;Developer Generated Content&rdquo;</span><span className="c2">). You agree that you have and
                  will maintain, for yourself and on behalf of your licensors, all necessary rights, consents, and permissions
                  to provide Developer Generated Game to the Platform and that the Developer Generated Game does not and will
                  not infringe upon or violate intellectual property rights, publicity rights, privacy rights or any other
                  rights of anyone else, including BOOM DAO.</span></p>
              <Space size="small" />
              <h4 className="c5 h.ff999dppf7zb"><span className="c1">3.4 Digital Wallet</span></h4>
              <Space size="small" />
              <p className="c5"><span className="c12">Transactions on the Platform requires you to link an accepted digital wallet
                (</span><span className="c8">&ldquo;Digital Wallet&quot;</span><span className="c2">) to the Platform for so long as
                  you use the Platform. We neither own nor control your Digital Wallets, any associated blockchain, or any
                  other Third-Party Services (as defined below). You have the sole responsibility to (a) establish, and
                  maintain, in fully operational, secure and valid status, access to your Digital Wallet, and (b) maintain, in
                  your fully secure possession, the credentials for accessing your Digital Wallet and the private key for your
                  Digital Wallet. In the event of any loss, hack or theft of any Digital Asset from your Digital Wallet,
                  including any cryptocurrency, any NFT or other non-fungible token, you acknowledge and agree that you shall
                  have no right(s), claim(s) or causes of action in any way whatsoever against BOOM DAO for such loss, hack or
                  theft, including with respect to any such Digital Asset.</span></p>
              <Space size="small" />
              <h4 className="c5 h.fiuisq39h7pa"><span className="c1">3.5 Prohibitions</span></h4>
              <Space size="small" />
              <p className="c5"><span className="c2">You agree not to use the Platform to:</span></p>
              <ol className="c10 lst-kix_7yyy8e5ncwo2-0 start">
                <li className="c0 li-bullet-0"><span className="c2">Violate any law, regulation, or governmental policy in the US, EU,
                  or internationally;</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Infringe upon or violate intellectual property rights or any other
                  rights of anyone else (including BOOM DAO);</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Jeopardize the security of your Digital Wallet or anyone
                  else&rsquo;s Digital Wallet;</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Impersonate or attempt to impersonate another individual, entity,
                  Play3 Ltd employee, BOOM DAO contributor, agent, or another user of the Platform;</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Infringe, in any way, on the rights of others or engage in or
                  promote any behavior or activity that is harmful, offensive, fraudulent, deceptive, threatening,
                  harassing, dangerous, defamatory, obscene, profane, discriminatory or otherwise illegal or
                  objectionable;</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Copy or store any Platform source code or a significant portion of
                  BOOM DAO Materials;</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Decompile, reverse engineer, or otherwise attempt to obtain source
                  code or underlying ideas or information of or relating to the Platform we provide;</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Attempt to gain unauthorized access to, interfere with, damage, or
                  disrupt any parts of the Platform, the server on which any part of the Platform requires, or any other
                  computer or database connected to the Platform;</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Circumvent, remove, alter, deactivate, degrade, or thwart any
                  technological measure or content protections of the Platform;</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Attack the Platform via a denial-of-service attack or distributed
                  denial-of-service attack;</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Use the Platform to engage in price manipulation, fraud, or other
                  deceptive, misleading, or manipulative activity;</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Use the platform to buy, sell, or transfer stolen items,
                  fraudulently obtained items, items taken without authorization, and/or any other illegally obtained
                  items;</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Use any device, software, bot, or routine that interferes with the
                  proper working of the Platform;</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Use any manual or automated process to monitor or copy any of the
                  material on the Platform or for any other unauthorized purpose, including, without limitation, using any
                  automated or non-automated systems to scape, copy, or distribute content without our prior written
                  consent;</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Damage, overburden, disable, or impair the Platform;</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Introduce any viruses, trojan horses, worms, logic bombs, or other
                  material that is malicious or technologically harmful;</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Engage in any other conduct that restricts or inhibits
                  anyone&rsquo;s use or enjoyment of the Platform, or which, as determined by us, may harm or offend BOOM
                  DAO or its users, or otherwise expose them to any liability;</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Upload or otherwise submit any Developer Generated Game or material
                  that is deliberately designed to provoke or antagonize people, especially trolling and bullying, or is
                  intended to harass, harm, hurt, scare, distress, embarrass or upset people; or</span></li>
                <li className="c0 li-bullet-0"><span className="c2">Otherwise attempt to interfere with the proper working of the
                  Platform.</span></li>
              </ol>
              <Space size="small" />
              <h4 className="c5 h.tg3n81fmjfl"><span className="c1">3.6 Third-Party Services Acknowledgement</span></h4>
              <Space size="small" />
              <p className="c5"><span className="c12">You acknowledge that the Platform and its functionality includes both services
                offered by third parties (</span><span className="c8">&ldquo;Third-Party Services&rdquo;</span><span
                  className="c2">) as well as BOOM DAO&rsquo;s proprietary technology. Certain functionality of the Platform may
                  incorporate, use or otherwise depend on Third-Party Services. If any event were to disrupt any functionality
                  dependent on a Third-Party Service, the Platform may similarly experience a disruption, and we shall not be
                  responsible or liable for any such disruption.<br></br></span></p>
              <Space size="small" />
              <h3 className="c5 h.tfy2snk91xfd"><span className="c4">4. Ownership of the Platform and User Generated Content</span>
                <Space size="small" />
              </h3>
              <Space size="small" />
              <h4 className="c5 h.nvmynud9cakc"><span className="c1">4.1 Ownership of the Platform</span></h4>
              <Space size="small" />
              <p className="c5"><span className="c12">You acknowledge and agree that we (or, as applicable, our licensors) own all right,
                title, and interest in and to all elements of the Platform, including, without limitation, all graphics,
                design, systems, methods, information, computer code, software, services, &ldquo;look and feel&rdquo;,
                organization, compilation of the content, code, data, and all other elements of the Platform, including any
                artwork that is created by BOOM DAO or its licensors and incorporated into any NFTs (collectively, the
              </span><span className="c8">&ldquo;BOOM DAO Materials&rdquo;</span><span className="c2">). The Platform and BOOM DAO
                Materials are protected by copyright, trade dress, trademark, patent laws, international conventions, other
                relevant intellectual property and proprietary rights, and applicable laws. Your use of the Platform does
                not grant you ownership of any other rights with respect to the BOOM DAO Materials or the Platform, whether
                expressly, by implication, estoppel, reliance or otherwise, all of which are specifically excluded and
                disclaimed.</span></p>
              <Space size="small" />
              <h4 className="c5 h.eauidjpek5g0"><span className="c1">4.2 Developer Generated Game</span></h4>
              <Space size="small" />
              <p className="c5"><span className="c2">You or your licensors shall own all right, title and interest in and to the Developer
                Generated Game you create. Any Developer Generated Game will be considered non-confidential and
                non-proprietary and you agree not to post any Developer Generated Game to the Platform that you or others
                may consider to be confidential or proprietary. By submitting Developer Generated Game via the Platform, you
                hereby grant to BOOM DAO an unconditional, irrevocable, non-exclusive, royalty-free, perpetual, fully
                transferable, assignable, and sublicensable worldwide license to use, reproduce, display, distribute,
                modify, and create derivative works of the Developer Generated Game for any lawful purpose.</span></p>
              <Space size="small" />
              <h4 className="c5 h.qgburhj4mc9t"><span className="c1">4.3 FEEDBACK</span></h4>
              <Space size="small" />
              <p className="c5"><span className="c12">If you transmit any communication or material to us by mail, email, telephone, or
                otherwise through the Platform, suggesting or recommending changes to the Platform, including without
                limitation, new features or functionality relating thereto, or any comments, questions, suggestions, or the
                like (</span><span className="c8">&quot;Feedback&quot;</span><span className="c2">), we are free to use such
                  Feedback irrespective of any other obligation or limitation between you and us governing such Feedback. All
                  Feedback is and will be treated as non-confidential. You hereby assign to us on your behalf, all right,
                  title, and interest in, and we are free to use, without any attribution or compensation to you or any third
                  party, any ideas, know-how, concepts, techniques, or other intellectual property rights contained in the
                  Feedback, for any purpose whatsoever, although we are not required to use any Feedback.<br></br></span></p>
              <Space size="small" />
              <h3 className="c5 h.r5c4brxm9dp7"><span className="c4">5. PRIVACY POLICY</span></h3>
              <Space size="small" />
              <p className="c5"><span className="c12">Our privacy policy found at </span><span className="c7"><a className="c11"
                href="https://www.google.com/url?q=https://docs.google.com/document/d/1zr8Bcrpr1pQLbXrXIXYh2G0ZkZUQY_WwhQUJEao6yqE/edit&amp;sa=D&amp;source=editors&amp;ust=1709616411676833&amp;usg=AOvVaw3_47MdLmRW9Vw-eFkFkGuz">URL
                Link</a></span><span className="c2">&nbsp;(&ldquo;Privacy Policy&rdquo;) describes the ways we collect, use,
                  store, and share your personal information collected through the use of the Platform, and is hereby
                  incorporated by this reference into these Terms. You agree to the collection, use, storage, and disclosure
                  of your data in accordance with our Privacy Policy.<br></br></span></p>
              <Space size="small" />
              <h3 className="c5 h.psijyz5lt6iu"><span className="c4">6. Release of Disputes with Users</span></h3>
              <Space size="small" />
              <p className="c5"><span className="c2">IF YOU HAVE A DISPUTE WITH ONE OR MORE USERS RELATED TO A TRANSACTION, YOU RELEASE US
                FROM CLAIMS, DEMANDS, AND DAMAGES OF EVERY KIND AND NATURE, KNOWN AND UNKNOWN, ARISING OUT OF OR IN ANY WAY
                CONNECTED WITH SUCH DISPUTES. IN ENTERING INTO THIS RELEASE YOU EXPRESSLY WAIVE ANY PROTECTIONS (WHETHER
                STATUTORY OR OTHERWISE) THAT WOULD OTHERWISE LIMIT THE COVERAGE OF THIS RELEASE TO INCLUDE THOSE CLAIMS
                WHICH YOU MAY KNOW OR SUSPECT TO EXIST IN YOUR FAVOR AT THE TIME OF AGREEING TO THIS RELEASE.<br></br></span></p>
              <Space size="small" />
              <h3 className="c5 h.boufler6f6pc"><span className="c4">7. Downtime Disclaimer</span></h3>
              <Space size="small" />
              <p className="c5"><span className="c12">BOOM DAO</span><span className="c12">&nbsp;uses commercially reasonable efforts to
                provide access to the Platform in a reliable and secure manner. From time to time, interruptions, errors,
                delays, or other deficiencies in providing access to the Platform or a Third-Party Service may occur due to
                a variety of factors, some of which are outside of BOOM DAO&rsquo;s control, and some which may require or
                result in scheduled maintenance or unscheduled downtime of the Platform (collectively, </span><span
                  className="c8">&ldquo;Downtime&rdquo;</span><span className="c2">). Part or all of the Platform may be unavailable
                    during any such period of Downtime, which may include an inability to make a transaction at the time you
                    intended. BOOM DAO shall not be liable or responsible to you for any inconvenience, losses or any other
                    damages as a result of Downtime. You hereby waive any claim against BOOM DAO arising out of or in connection
                    with Downtime.<br></br></span></p>
              <Space size="small" />
              <h3 className="c5 h.de3mjo1heykh"><span className="c4">8. DISCLAIMERS; NO REPRESENTATIONS; LIMITATIONS ON OUR LIABILITY</span></h3>
              <Space size="small" />
              <h4 className="c5 h.xy47m5g3gsde"><span className="c1">8.1 DISCLAIMER OF WARRANTIES:</span></h4>
              <Space size="small" />
              <p className="c5"><span className="c2">YOUR ACCESS TO AND USE OF THE PLATFORM IS AT YOUR OWN RISK. THE PLATFORM AND DIGITAL
                ASSETS ARE PROVIDED &ldquo;AS IS&rdquo; AND WITHOUT ANY WARRANTY OF ANY KIND. TO THE EXTENT PERMITTED BY
                APPLICABLE LAW, BOOM DAO, DISCLAIMS ALL WARRANTIES, CONDITIONS, AND REPRESENTATIONS OF ANY KIND, WHETHER
                EXPRESS, IMPLIED, STATUTORY, OR OTHERWISE, INCLUDING THOSE RELATED TO TITLE, MERCHANTABILITY, FITNESS FOR A
                PARTICULAR PURPOSE, NON-INFRINGEMENT, AND THOSE ARISING OUT OF COURSE OF DEALING OR USAGE OF TRADE. BOOM DAO
                MAKES NO REPRESENTATION OR WARRANTY: (A) THAT THE PLATFORM OR ANY CONTENT OR INFORMATION DISPLAYED ON OR
                MADE AVAILABLE ON OR THROUGH THE PLATFORM, INCLUDING ANY PLATFORM CONTENT, DIGITAL ASSETS, OR ANY OTHER
                CONTENT OR INFORMATION DISPLAYED ON OR THROUGH THE PLATFORM: (i) WILL MEET YOUR REQUIREMENTS; (ii) WILL BE
                AVAILABLE ON AN UNINTERRUPTED, TIMELY, SECURE, OR ERROR-FREE BASIS; (iii) ARE OR WILL BE FREE OF MALICIOUS
                CODE; OR (iv) WILL BE ACCURATE, COMPLETE, RELIABLE, CURRENT, LEGAL, OR SAFE; (B) AS TO THE VALUE OR TITLE OF
                ANY DIGITAL ASSETS OR ANY OTHER CONTENT OR INFORMATION DISPLAYED ON OR THROUGH THE PLATFORM; OR (C) IN
                RELATION TO THE CONTENT OF ANY THIRD-PARTY SERVICES LINKED TO OR INTEGRATED WITH THE PLATFORM.</span></p>
              <p className="c5"><span className="c2">BOOM DAO IS NOT RESPONSIBLE OR LIABLE FOR ANY SUSTAINED LOSSES OR INJURY CAUSED BY
                ANY EXPLOITATION, VULNERABILITY OR OTHER FORM OF FAILURE OR MISFUNCTIONING OF SOFTWARE INCLUDING APPLICABLE
                DIGITAL WALLETS AND SMART CONTRACTS.</span></p>
              <p className="c5"><span className="c2">IN ADDITION, WE SHALL NOT BE RESPONSIBLE OR LIABLE TO YOU FOR ANY LOSSES YOU INCUR AS
                THE RESULT OF (A) USER ERROR, SUCH AS FORGOTTEN PASSWORDS OR INCORRECTLY CONSTRUED SMART CONTRACTS OR OTHER
                TRANSACTIONS; (B) SERVER FAILURE OR DATA LOSS; (C) CORRUPTED WALLET FILES; OR (D) UNAUTHORIZED ACCESS OR
                ACTIVITIES BY THIRD PARTIES, INCLUDING, BUT NOT LIMITED TO THE USE OF VIRUSES, PHISHING, BRUTE FORCING, OR
                OTHER MEANS OF ATTACK AGAINST THE PLATFORM, APPLICABLE BLOCKCHAIN, OR A DIGITAL WALLET.</span></p>
              <Space size="small" />
              <h4 className="c5 h.izjqjfpeai5j"><span className="c1">8.2 Limitation of Liability</span></h4>
              <Space size="small" />
              <p className="c5"><span className="c12">BOOM DAO</span><span className="c12">, AND ITS PARENT AND ITS AFFILIATES, AND ITS AND
                THEIR RESPECTIVE OFFICERS, DIRECTORS, SHAREHOLDERS, EMPLOYEES, CONTRACTORS, SERVICE PROVIDERS, LICENSORS,
                AND AGENTS (ALL OF THE FOREGOING, </span><span className="c8">&ldquo;BOOM DAO PARTIES&rdquo;</span><span
                  className="c2">) SHALL NOT BE LIABLE TO YOU OR ANY THIRD PARTY FOR CONTRACT, TORT, OR ANY OTHER TYPES OF
                  DAMAGES, INCLUDING DIRECT, INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL, PUNITIVE, OR EXEMPLARY DAMAGES,
                  UNDER THESE TERMS OR ARISING OUT OF OR RELATED TO THE PLATFORM OR ANY DIGITAL ASSET, INCLUDING, WITHOUT
                  LIMITATION: (I) PARTICIPATION IN OR THE OUTCOME OF A TRANSACTION MADE USING THE PLATFORM, OR (II) ANY
                  TRANSACTION RELATED TO $BOOM (INCLUDING THOSE UTILIZING A THIRD-PARTY SERVICE).</span></p>
              <p className="c5"><span className="c2">IF APPLICABLE LAW DOES NOT ALLOW ALL OR ANY PART OF THE ABOVE DISCLAIMERS OR
                LIMITATION OF LIABILITY TO APPLY TO YOU, SUCH DISCLAIMERS AND/OR LIMITATIONS WILL APPLY TO YOU ONLY TO THE
                EXTENT PERMITTED BY APPLICABLE LAW.<br></br></span></p>
              <Space size="small" />
              <h3 className="c5 h.42ojshhbqi2g"><span className="c4">9. ASSUMPTION OF RISK</span></h3>
              <Space size="small" />
              <p className="c5"><span className="c2">You hereby acknowledge and assume the risk of using and making a transaction through
                the Platform and take full responsibility and liability for the outcome of actions initiated. Without
                limiting any risks that exist, you acknowledge the following risks related to blockchain technology,
                cryptocurrencies and non-fungible tokens:</span></p>
              <ul className="c10 lst-kix_ieki9yoogtey-0 start">
                <li className="c0 li-bullet-0"><span className="c8">Regulatory uncertainty.</span><span className="c2">&nbsp;The regulatory
                  regime governing blockchain technologies, non-fungible tokens, cryptocurrency, and other crypto-based
                  items is uncertain, and new regulations or policies may materially adversely affect the development of
                  the Platform.</span></li>
                <li className="c0 li-bullet-0"><span className="c8">Blockchain technology risk.</span><span className="c2">&nbsp;There are
                  risks associated with using Internet and blockchain based products, including, but not limited to, the
                  risk associated with hardware, software, and Internet connections, the risk of malicious software
                  introduction, and the risk that third parties may obtain unauthorized access to your Digital Wallet or
                  account.</span></li>
                <li className="c0 li-bullet-0"><span className="c8">Digital asset risks.</span><span className="c2">&nbsp;There are risks
                  associated with purchasing items associated with content created by third parties through peer-to-peer
                  transactions, including, but not limited to, the risk that items are vulnerable to metadata decay, bugs
                  in smart contracts, and items that may become untransferable. You represent and warrant that you have
                  done sufficient research before making any decisions to sell, obtain, transfer, or otherwise interact
                  with any non-fungible tokens.</span></li>
                <li className="c0 li-bullet-0"><span className="c8">Third-Party Services.</span><span className="c2">&nbsp;We do not control
                  Third-Party Services like the Ethereum network or other public blockchains, Digital Wallets, or other
                  third party products that you may be interacting with, and we do not control third-party smart contracts
                  and protocols that may be integral to your ability to complete transactions on these public
                  blockchains.</span></li>
              </ul>
              <p className="c0 c3"><span className="c2"></span></p>
              <Space size="small" />
              <h3 className="c5 h.gz8ereif5eim"><span className="c4">10. DISPUTE RESOLUTION - ARBITRATION</span></h3>
              <Space size="small" />
              <p className="c5"><span className="c12">Please read the following arbitration agreement in this section (</span><span
                className="c8">&ldquo;Arbitration Agreement&rdquo;</span><span className="c2">) carefully as it requires you to
                  arbitrate disputes with BOOM DAO and limits the manner in which you can seek relief from us.</span></p>
              <p className="c5"><span className="c2">You agree that any dispute or claim relating in any way to your access or use of the
                Platform, to any transaction made through the Platform, or to any aspect of your relationship with BOOM DAO,
                will be resolved by binding arbitration, rather than in court, except that (1) you may assert claims in
                small claims court if your claims qualify; and (2) you or BOOM DAO may seek equitable relief in court for
                infringement or other misuse of intellectual property rights (such as trademarks, trade dress, domain names,
                trade secrets, copyrights, and patents).</span></p>
              <p className="c5"><span className="c2">The Federal Arbitration Act governs the interpretation and enforcement of this
                Arbitration Agreement. To begin an arbitration proceeding, you must send a letter requesting arbitration
                with a description of your claim to our team@boomdao.xyz. The arbitration shall be conducted by JAMS, an
                established alternative dispute resolution provider. If JAMS is not available to arbitrate, the Parties
                shall select an alternative arbitral forum. Any judgment on the award rendered by the arbitrator may be
                entered in any court of competent jurisdiction.</span></p>
              <p className="c5"><span className="c2">The arbitrator shall have exclusive authority to (a) determine the scope and
                enforceability of this Arbitration Agreement and (b) resolve any dispute related to the interpretation,
                applicability, enforceability, or formation of this Arbitration Agreement including, but not limited to any
                claim that all or any part of this Arbitration Agreement is void or voidable. The arbitrator shall have the
                authority to grant motions dispositive of all or part of any claim, to award monetary damages, and to grant
                any non-monetary remedy or relief available to an individual under applicable law, the arbitral
                forum&rsquo;s rules, and these Terms (including the Arbitration Agreement). The arbitrator has the same
                authority to award relief on an individual basis that a judge in a court of law would have. The award of the
                arbitrator is final and binding upon you and us.</span></p>
              <p className="c5"><span className="c2">YOU AND BOOM DAO HEREBY WAIVE ANY CONSTITUTIONAL AND STATUTORY RIGHTS TO SUE IN COURT
                AND HAVE A TRIAL IN FRONT OF A JUDGE OR A JURY, EXCEPT AS SPECIFIED IN NUMBER 1 ABOVE.</span></p>
              <p className="c5"><span className="c2">ALL CLAIMS AND DISPUTES WITHIN THE SCOPE OF THIS ARBITRATION AGREEMENT MUST BE
                ARBITRATED ON AN INDIVIDUAL BASIS AND NOT ON A COLLECTIVE CLASSName BASIS. ONLY INDIVIDUAL RELIEF IS
                AVAILABLE.</span></p>
              <p className="c5"><span className="c2">You have the right to opt out of the provisions of this Arbitration Agreement by
                sending written notice of your decision to opt out within thirty (30) days after first becoming subject to
                this Arbitration Agreement to team@boomdao.xyz. If you opt out of this Arbitration Agreement, all other
                parts of the Terms will continue to apply to you.</span></p>
              <p className="c5"><span className="c2">Except as provided in this section, if any part or parts of this Arbitration
                Agreement are found under the law to be invalid or unenforceable, then such specific part or parts shall be
                of no force and effect and shall be severed and the remainder of the Arbitration Agreement shall continue in
                full force and effect.</span></p>
              <p className="c5"><span className="c2">This Arbitration Agreement shall survive the termination of your relationship with
                BOOM DAO.<br></br></span></p>
              <Space size="small" />
              <h3 className="c5 h.cl0lh3mafqym"><span className="c4">11. COMPLIANCE WITH LAW; DISQUALIFIED PERSONS</span></h3>
              <Space size="small" />
              <p className="c5"><span className="c2">You represent and warrant that you will comply with all applicable laws (e.g., local,
                state, federal and other laws) when using the Platform.You are solely responsible for ensuring that your
                access and use of the Platform in your country, territory or jurisdiction does not violate any applicable
                laws.</span></p>
              <p className="c5"><span className="c2">You are not authorized to use the Platform if there are applicable legal restrictions
                in your country of residence that would make the use of the Platform illegal. It is your sole responsibility
                to ensure that your use of the Platform is not prohibited, restricted, curtailed, hindered, impaired or
                otherwise adversely affected in any way by any applicable law in your country of residence or domicile. In
                addition, you are not authorized to use the Platform if you are:</span></p>
              <ol className="c10 lst-kix_gly0y9d9x1lx-0 start">
                <li className="c0 li-bullet-0"><span className="c12">a citizen, domiciled in, resident of, or physically present /
                  located in Iran, North Korea, Cuba, Syria, China, Afghanistan, Central African Republic (the), Congo
                  (the Democratic Republic of the), Libya, Mali, Somalia, Sudan, and Yemen (each an </span><span
                    className="c8">&ldquo;Excluded Jurisdiction&rdquo;</span><span className="c2">);</span></li>
                <li className="c0 li-bullet-0"><span className="c2">a corporate body: (i) which is incorporated in, or operates out of,
                  an Excluded Jurisdiction, or (ii) which is under the control of one or more individuals who is/are
                  citizens of, domiciled in, residents of, or physically present / located in, an Excluded
                  Jurisdiction;</span></li>
                <li className="c0 li-bullet-0"><span className="c12">an individual or body corporate: (i) included in the consolidated
                  list published by the United Nations Security Council of individuals or entities subject to measures
                  imposed by the United Nations Security Council accessible at </span><span className="c9"><a className="c11"
                    href="https://www.google.com/url?q=https://www.un.org/securitycouncil/content/un-sc-consolidated-list&amp;sa=D&amp;source=editors&amp;ust=1709616411680839&amp;usg=AOvVaw1vR8ysoEBEe8judwUzKHD2">https://www.un.org/securitycouncil/content/un-sc-consolidated-list</a></span><span
                      className="c12">; or (ii) included in the United Nations Lists (UN Lists) or within the ambit of regulations
                    relating to or implementing United Nations Security Council Resolutions listed by MAS and accessible by
                  </span><span className="c9"><a className="c11"
                    href="https://www.google.com/url?q=https://www.mas.gov.sg/regulation/anti-money-laundering/targeted-financial-sanctions/lists-of-designated-individuals-and-entities&amp;sa=D&amp;source=editors&amp;ust=1709616411681185&amp;usg=AOvVaw1lXoghFnfXOrXX2uVyxkXi">https://www.mas.gov.sg/regulation/anti-money-laundering/targeted-financial-sanctions/lists-of-designated-individuals-and-entities</a></span><span
                      className="c2">; or</span></li>
                <li className="c0 li-bullet-0"><span className="c2">an individual or corporate body who is otherwise prohibited or
                  ineligible in any way, whether in full or in part, under any law applicable to such individual or
                  corporate body from participating in any part of the Platform.</span></li>
              </ol>
              <p className="c5"><span className="c12">If you are not authorized to use the Platform under this Section 12, you are deemed
                a </span><span className="c8">&ldquo;Disqualified Person&rdquo;</span><span className="c2">&nbsp;under these
                  Terms.<br></br></span></p>
              <Space size="small" />
              <h3 className="c5 h.soc3kt33pngr"><span className="c4">12. INDEMNIFICATION</span></h3>
              <Space size="small" />
              <p className="c5"><span className="c2">You agree to defend, indemnify and hold harmless the BOOM DAO Parties from and
                against any and all claims, costs, proceedings, demands, losses, damages, and expenses (including, without
                limitation, reasonable attorney&rsquo;s fees and legal costs) of any kind or nature relating to third party
                claims arising out of (a) any actual or alleged breach of these Terms by you, a co-conspirator, anyone using
                your account, (b) your use of the Platform or purchase or use of any Digital Asset, (c) your violation of
                the rights of or obligations to a third party, including another user or third-party, and (d) your
                negligence or willful misconduct. If we assume the defense of such a matter, you shall reasonably cooperate
                with us in such defense.<br></br></span></p>
              <Space size="small" />
              <h3 className="c5 h.emua1pml887"><span className="c4">13. MISCELLANEOUS TERMS</span></h3>
              <Space size="small" />
              <h4 className="c5 h.9meub0q66sy2"><span className="c1">13.1 No Waiver of Rights</span></h4>
              <Space size="small" />
              <p className="c5"><span className="c2">The failure by us to enforce any right or provision of these Terms shall not prevent
                us from enforcing such right or provision in the future. No waiver by us of any of the provisions of these
                Terms is effective unless explicitly set forth in writing and signed by us. No failure to exercise, or delay
                in exercising, any right, remedy, power or privilege arising from these Terms operates, or may be construed,
                as a waiver thereof. No single or partial exercise of any right, remedy, power or privilege hereunder
                precludes any other or further exercise thereof or the exercise of any other right, remedy, power, or
                privilege.</span></p>
              <Space size="small" />
              <h4 className="c5 h.k6sj21ucpa1"><span className="c1">13.2 Export Laws</span></h4>
              <Space size="small" />
              <p className="c5"><span className="c2">You agree that you will not export or re-export, directly or indirectly, the
                Platform, and/or other information or materials provided by BOOM DAO hereunder, to any Excluded Jurisdiction
                or Disqualified Person.</span></p>
              <Space size="small" />
              <h4 className="c5 h.j898k0fukud7"><span className="c1">13.3 Assignment</span></h4>
              <Space size="small" />
              <p className="c5"><span className="c2">We may assign our rights and obligations under these Terms, including in connection
                with a merger, acquisition, sale of assets or equity, or by operation of law. You shall not assign any of
                your rights or delegate any of your obligations under these Terms without our prior written consent. Any
                purported assignment or delegation in violation of this Section is null and void. No assignment or
                delegation relieves either party of any of its obligations under these Terms.</span></p>
              <Space size="small" />
              <h4 className="c5 h.30pn268kd1jp"><span className="c1">13.4 Severability</span></h4>
              <Space size="small" />
              <p className="c5"><span className="c2">If any provision of these Terms are found to be unlawful or unenforceable, then that
                provision shall be deemed severable from these Terms and shall not affect the enforceability of any other
                provisions.</span></p>
              <Space size="small" />
              <h4 className="c5 h.rq2j98589tan"><span className="c1">13.5 Governing Law and Jurisdiction</span></h4>
              <Space size="small" />
              <h4 className="c5 h.tj223p7g3d7a"><span className="c12 c13">These Terms and any and all claims, disputes or other legal
                proceedings by or between you and us, including but not limited to any claims or disputes that are in any
                way related to or arising out of these Terms or your use of or access to the Service, shall be governed by
                and construed in accordance with the law of England and Wales, without regard to any principles of conflicts
                of law.</span>
                <Space size="small" />
                <span className="c1">13.6 Entire Agreement</span></h4>
              <Space size="small" />
              <p className="c5"><span className="c2">These Terms constitute the sole and entire agreement of the parties with respect to
                the subject matter contained herein, and supersedes all prior and contemporaneous understandings and
                agreements, both written and oral, with respect to such subject matter.</span></p>
              <Space size="small" />
              <h4 className="c5 h.mt4h1yyvho3d"><span className="c1">13.7 Headings</span></h4>
              <Space size="small" />
              <p className="c5"><span className="c2">The headings of the sections and subsections contained in these Terms are included
                for reference purposes only, solely for the convenience of the parties, and shall not in any way be deemed
                to affect the meaning, interpretation or applicability of these Terms or any term, condition or provision
                hereof.</span></p>
              <h1 className="c16 h.a5pv5xo0p5je"><span className="c14"></span></h1>
            </div>
            <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
          </div>
        </div>
      </div>
    ));
  };

  const handlePPClick = () => {
    setIsOpenNavSidebar(false);
    toast.custom((t) => (
      <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
        <div className="w-3/4 rounded-3xl mb-7 p-0.5 gradient-bg mt-32 inline-block">
          <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
            <p className="text-2xl font-bold mt-4">Privacy Policy</p>
            <p className="ppc5 c3"><span className="ppc1"></span></p>
            <p className="ppc5 c3"><span className="ppc1"></span></p>
            <div className="overflow-y-auto h-80 px-20">
              <p className="ppc3"><span className="ppc7">Effective Date:</span><span className="ppc1">&nbsp;March 1, 2024<br></br></span></p>
              <Space size="small" />
              <p className="ppc3"><span>Play3 Ltd (</span><span className="ppc7">&quot;BOOM DAO&quot;</span><span>, </span><span
                className="ppc7">&quot;we&quot;</span><span>, </span><span className="ppc7">&quot;us&quot;</span><span>, or </span><span
                  className="ppc7">&quot;our&quot;</span><span>) recognizes the importance of protecting the privacy of the users of
                    our service. It is our intent to balance our legitimate business interests in collecting and using
                    information received from and about you with your reasonable expectations of privacy. The following privacy
                    policy (</span><span className="ppc7">&ldquo;Privacy Policy&rdquo;</span><span>) is the way we handle information
                      learned about you from your visits to our website available at </span><span className="ppc6"><a className="ppc4"
                        href="https://boomdao.xyz/">boomdao.xyz</a></span><span>,
                </span><span className="ppc6"><a className="ppc4"
                  href="https://launcher.boomdao.xyz/"> launcher.boomdao.xyz</a></span><span>,
                    and any other website offered by us that links to this privacy policy (collectively the </span><span
                      className="ppc7">&ldquo;Site&rdquo;</span><span className="ppc1">).<br></br></span></p>
              <Space size="small" />
              <p className="ppc3"><span className="ppc7">PLEASE REVIEW THIS PRIVACY POLICY CAREFULLY</span><span>&nbsp;When you submit
                information to or through the Site, you consent to the collection and processing of your information as
                described in this Privacy Policy. By using the Site, you accept the terms of this Privacy Policy and our
              </span><span className="ppc6"><a className="ppc4"
                href="https://www.google.com/url?q=https://docs.google.com/document/d/1hD3-w6PKSeDMEecMNuE87jZylf8xe9TTa-eYabjMJTY/edit&amp;sa=D&amp;source=editors&amp;ust=1709619561490173&amp;usg=AOvVaw2mZR37lT_jn7nI6FnFQt0v">Terms
                of Service</a></span><span className="ppc1">.<br></br></span></p>
              <Space size="small" />
              <p className="ppc3"><span className="ppc0">Personal Information</span></p>
              <p className="ppc3"><span>BOOM DAO</span><span className="ppc1">&nbsp;collects personal information from you when you interact
                with the Site. This information is collected and stored electronically by us. Certain information may be
                provided to us voluntarily by you, collected automatically by us from you, or received by us from a third
                party source.<br></br></span></p>
              <Space size="small" />
              <h3 className="ppc3 h.bs4zh8bq8k3a"><span className="ppc5">1. Information Voluntarily Provided By You</span></h3>
              <Space size="small" />
              <p className="ppc3"><span className="ppc1">We collect information about you when you use certain aspects of the Site, including
                information you provide when you link a digital wallet, make a transaction, or contact our support team.
                Such information includes:</span></p>
              <ul className="ppc10 lst-kix_ixklt37qm15i-0 start">
                <li className="ppc2 li-bullet-0"><span className="ppc7">Contact Data</span><span className="ppc1">, in the form of your email
                  address and other contact information you provide.</span></li>
                <li className="ppc2 li-bullet-0"><span className="ppc7">Profile information</span><span className="ppc1">, including information
                  you provide about yourself and aesthetics you may set in your profile for other users of the Site to
                  see, including username, profile picture, profile picture frame, banner image, name modifiers and
                  cosmetic effects.</span></li>
                <li className="ppc2 li-bullet-0"><span className="ppc7">Digital Wallet Information</span><span className="ppc1">, including your
                  digital wallet address.</span></li>
                <li className="ppc2 li-bullet-0"><span className="ppc7">Transaction Event Data</span><span className="ppc1">, including but not
                  limited to applicable public IDs related to the transaction, transaction price information, and the date
                  and time of the transaction.</span></li>
                <li className="ppc2 li-bullet-0"><span className="ppc7">Content</span><span className="ppc1">, including any content in messages
                  you may send to us.</span></li>
              </ul>
              <Space size="small" />
              <p className="ppc3"><span className="ppc1">You may choose to voluntarily provide other information to us that we do not request,
                and, in such instances, we have no control over what categories of personal information such disclosure may
                include. Any additional information provided by you to us is provided at your own risk.<br></br></span></p>
              <Space size="small" />
              <h3 className="ppc3 h.hodzfl4uvox4"><span className="ppc5">2. Information Collected Automatically</span></h3>
              <Space size="small" />
              <p className="ppc3"><span>BOOM DAO</span><span className="ppc1">&nbsp;also collects certain personal information about you
                automatically when you use the Site. This information includes information about your computer hardware,
                software, and network when you access or use the Site. This information may include: your IP address,
                browser type, domain names, access times, geographic location, referring website addresses and other
                technical information such as protocol status and substatus, bytes sent and received, and server
                information. We may also collect information about how you interact with the Site. This information is used
                by us for our business purposes, for the operation and improvement of the Site, for technical
                troubleshooting, to maintain quality of the Site and to provide general statistics regarding use of the
                Site.<br></br></span></p>
              <Space size="small" />
              <h3 className="ppc3 h.mfmlf27i2k9s"><span className="ppc5">3. Information Received From a Third Party Source</span></h3>
              <Space size="small" />
              <p className="ppc3"><span className="ppc1">The Site incorporates blockchain technology, and as such, certain transactions that
                you engage in on the blockchain will be publicly available. We may collect certain information from such
                public sources.</span></p>
              <Space size="small" />
              <p className="ppc3"><span className="ppc0">Cookies and Other Information Collection Tools</span></p>
              <p className="ppc3"><span className="ppc1">We currently do not collect any cookies or otherwise use any tracking technologies on
                our Site, however, third-party sites that may be linked through our Site may use cookies or other tracking
                technologies. If we decide to use cookies or other tracking technologies other than necessary or essential
                cookies, we will inform you by updating this Privacy Policy.</span></p>
              <Space size="small" />
              <p className="ppc3"><span className="ppc0">How Information is Used</span></p>
              <p className="ppc3"><span className="ppc1">We may use the information we collect for any of the following purposes:</span></p>
              <ul className="ppc10 lst-kix_u0vwj8ea207a-0 start">
                <li className="ppc2 li-bullet-0"><span className="ppc1">to provide the Site to you and to improve the Site and user
                  experience;</span></li>
                <li className="ppc2 li-bullet-0"><span className="ppc1">to provide you with items you purchased;</span></li>
                <li className="ppc2 li-bullet-0"><span className="ppc1">to provide you with any applicable airdrops;</span></li>
                <li className="ppc2 li-bullet-0"><span className="ppc1">for customer service, security, to detect fraud or illegal
                  activities, and for archival and backup purposes in connection with the provision of the Site;</span>
                </li>
                <li className="ppc2 li-bullet-0"><span className="ppc1">to fulfill any obligations related to BOOM DAO&rsquo;s smart
                  contract or the Terms of Services; </span></li>
                <li className="ppc2 li-bullet-0"><span className="ppc1">to communicate with you.</span></li>
              </ul>
              <Space size="small" />
              <p className="ppc3"><span className="ppc0">Sharing of Information</span></p>

              <ul className="ppc10 lst-kix_wa7k1xd48icf-0 start">
                <li className="ppc2 li-bullet-0"><span className="ppc7">With Third Party Service Providers Performing Services on Our
                  Behalf.</span><span className="ppc1">&nbsp;We share your personal information with our service providers to
                    perform the functions for which we engage them. For example, we may use third parties to host the Site
                    or assist us in providing functionality of the Site, provide data analysis and research on the use of
                    the Site</span></li>
                <li className="ppc2 li-bullet-0"><span className="ppc7">For Legal Purposes.</span><span className="ppc1">&nbsp;We also may share
                  information that we collect from users as needed to enforce our rights, protect our property or protect
                  the rights, property or safety of others, or as needed to support external auditing, compliance and
                  corporate governance functions. We will disclose personal information as we deem necessary to respond to
                  a subpoena, regulation, binding order of a data protection agency, legal process, governmental request
                  or any other legal or regulatory process. We may also share personal information as required to pursue
                  available remedies or limit damages we may sustain.</span></li>
                <li className="ppc2 li-bullet-0"><span className="ppc7">Blockchain Platform.</span><span className="ppc1">&nbsp;When you engage in
                  a transaction that is recorded on the blockchain, certain information that may be considered personal
                  information related to that transaction will be published on the blockchain and may be accessible to
                  third parties not controlled by BOOM DAO. Transactions recorded on the blockchain are permanently
                  recorded across a wide network of computer systems and are generally incapable of deletion. Many
                  blockchains are open to forensic analysis which can lead to deanonymization and the unintentional
                  revelation of personal information, especially when blockchain data is combined with other data.</span>
                </li>
                <li className="ppc2 li-bullet-0"><span className="ppc7">Changes of Control.</span><span className="ppc1">&nbsp;We share
                  information in connection with, or during negotiations of, any proposed or actual merger, purchase, sale
                  or any other type of acquisition, business combination of all or any portion of our business or assets,
                  change of control, or a transfer of all or a portion of our business or assets to another third party
                  (including in the case of any bankruptcy proceeding).</span></li>
              </ul>
              <Space size="small" />
              <p className="ppc3"><span className="ppc1">BOOM DAO does not share your personal information with third parties for those third
                parties&rsquo; direct marketing purposes.</span></p>
              <Space size="small" />
              <p className="ppc3"><span className="ppc0">Security Used &amp; Retention of Personal Information</span></p>
              <p className="ppc3"><span>BOOM DAO</span><span className="ppc1">&nbsp;uses reasonable security measures designed to prevent
                unauthorized intrusion to the Site and the alteration, acquisition or misuse of personal information that
                Treasure directly controls, however, we will not be responsible for loss, corruption or unauthorized
                acquisition or misuse of personal information that you provide through the Site that is stored by us, or for
                any damages resulting from such loss, corruption or unauthorized acquisition or misuse. It is your
                responsibility to protect the security of your Digital Wallet Information. We will retain your personal
                information for as long as necessary to fulfill the purpose for which it was collected, or as required by
                applicable laws or regulation.</span></p>
              <Space size="small" />
              <p className="ppc3"><span className="ppc0">Links to External Websites</span></p>
              <p className="ppc3"><span className="ppc1">Our Site may contain links to third party websites. Any access to and use of such
                third party websites is not governed by this Privacy Policy, but is instead governed by the privacy policies
                of those third party websites, and we are not responsible for the information practices of such third party
                websites.</span></p>
              <Space size="small" />
              <p className="ppc3"><span className="ppc0">Do Not Track</span></p>
              <p className="ppc3"><span>Our Site does not currently take any action when it receives a Do Not Track request. Do Not
                Track is a privacy preference that you can set in your web browser to indicate that you do not want certain
                information about your webpage visits collected across websites when you have not interacted with that
                service on the page. For details, including how to turn on Do Not Track, visit </span><span className="ppc13"><a
                  className="ppc4"
                  href="https://www.google.com/url?q=https://www.eff.org/issues/do-not-track&amp;sa=D&amp;source=editors&amp;ust=1709619561494965&amp;usg=AOvVaw0wT7-rJwUgHOt3BrHCxKhG">www.donottrack.us</a></span><span
                    className="ppc1">.</span></p>
              <Space size="small" />
              <p className="ppc3"><span className="ppc0">Children</span></p>
              <p className="ppc3"><span className="ppc1">We do not knowingly collect or maintain personal information from any person under
                the age of 18. No parts of our Site are directed to or designed to attract anyone under the age of
                thirteen.</span></p>
              <Space size="small" />
              <p className="ppc3"><span className="ppc0">Questions / Contact Us</span></p>
              <p className="ppc3"><span className="ppc1">If you have any questions regarding this Privacy Policy, please contact us at
                team@boomdao.xyz</span></p>
              <Space size="small" />
              <p className="ppc3"><span className="ppc0">Notification of Changes</span></p>
              <p className="ppc3"><span className="ppc1">Any changes to our Privacy Policy will be posted to this page so users are always
                aware of the information we collect and how we use it. Accordingly, please refer back to this Privacy Policy
                frequently as it may change.</span></p>
              <p className="ppc9"><span className="ppc1"></span></p>
              <Space size="small" />
            </div>
            <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
          </div>
        </div>
      </div>
    ));
  };

  return (
    <Disclosure as="nav">
      {({ open, close }) => (
        <div
          className={cx(
            "fixed top-0 z-50 w-full",
            openOrNotTop(open) &&
            "bg-white bg-opacity-95 shadow-sm dark:bg-dark dark:bg-opacity-95",
          )}
        >
          <div className="mx-auto w-full max-w-screen-xl px-8 py-4">
            <div className="flex items-center justify-between">
              <div className="relative mb-2 flex-shrink-0">
                <img
                  src={`/logo-${theme}.svg`}
                  width={148}
                  alt="logo"
                  className="hidden md:flex"
                />
                <img
                  src={`/logo.svg`}
                  width={42}
                  alt="logo"
                  className="md:hidden"
                />
              </div>
              <div className="hidden sm:ml-6 md:block">
                <div className="flex items-center gap-6">
                  <div className="hidden space-x-4 text-base uppercase md:flex">
                    {(session) ? (
                      paths.map(({ name, path }) => (
                        <NavLink
                          key={name}
                          className={({ isActive }) =>
                            isActive ? "gradient-text" : ""
                          }
                          to={path}
                          onClick={() => { setIsDropdownOpen(false); setSelectedOption("DEV TOOLS"); }}
                        >
                          {name}
                        </NavLink>
                      ))
                    ) : (
                      paths.map(({ name, path }) => (
                        <NavLink
                          key={name}
                          className={({ isActive }) =>
                            isActive ? "gradient-text" : ""
                          }
                          to={path}
                          onClick={() => { setIsDropdownOpen(false); setSelectedOption("DEV TOOLS"); setIsOpenNavSidebar(true); }}
                        >
                          {name}
                        </NavLink>
                      ))
                    )
                    }
                  </div>
                  <div
                    className="cursor-pointer relative"
                    onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                  >
                    {selectedOption || 'DEV TOOLS'}

                    {isDropdownOpen && (<dialog open className="whitespace-nowrap mt-5 dark:bg-white bg-black text-white dark:text-black" onMouseLeave={() => setIsDropdownOpen(false)}>
                      <div className="grid px-4 py-4">
                        {(session) ? (dev_tools.map(({ name, path }) => (
                          <NavLink
                            key={name}
                            className="hover:gradient-text my-2"
                            to={path}
                            onClick={() => handleOptionClickLoggedIn}
                          >
                            {name}
                          </NavLink>
                        ))) :
                          (dev_tools.map(({ name, path }) => (
                            <NavLink
                              key={name}
                              to={path}
                              onClick={() => setIsOpenNavSidebar(true)}
                            >
                              {name}
                            </NavLink>
                          )))}
                      </div>
                    </dialog>)}
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-4">
                <div className="flex items-center gap-4">
                  <div className="max-w-[240px] rounded-primary dark:border-gray-700 border-2 border-gray-300">
                    {(session == null) ? (
                      <Button
                        rightArrow
                        onClick={() => setIsOpenNavSidebar(true)}
                      >
                        {t("navigation.login")}
                      </Button>
                    ) : isLoading ? (
                      <Loader className="h-5 w-5"></Loader>
                    ) : (
                      <div
                        onClick={() => setIsOpenNavSidebar(true)}
                        className="cursor-pointer text-xs py-1 px-2"
                      >
                        <div className="flex">
                          <img src={userProfile?.image} className="h-10 w-10 object-cover rounded-3xl overflow-hidden" />
                          <div className="pl-1 pt-1">
                            <p className="gradient-text font-semibold">{userProfile?.username}</p>
                            <div className="flex pt-1">
                              <img src="/xpicon.png" className="w-4" />
                              <p className="text-black dark:text-white">{userProfile?.xp}</p>
                            </div>
                          </div>
                        </div>
                      </div>
                    )
                    }
                  </div>
                </div>

                <ThemeSwitcher className="text-black dark:text-white" />

                <SideBar open={isOpenNavSidebar} setOpen={setIsOpenNavSidebar}>
                  <div className="w-full h-screen p-6 text-center relative content-center">
                    {session ? (
                      <div>
                        <p className="font-semibold dark:text-white">Principal:</p>
                        <div>{session.address}</div>
                        <div className="space-y-4 mt-24 justify-center inline-block">
                          <Button size="big" onClick={() => { navigate((navPaths.profile_picture)); setIsOpenNavSidebar(false); }}>
                            {t("navigation.profile")}
                          </Button>
                          <Button size="big" onClick={() => { navigate((navPaths.wallet_tokens)); setIsOpenNavSidebar(false); window.location.reload(); }}>
                            {t("navigation.wallet")}
                          </Button>
                          <Button size="big" onClick={() => { logout(); navigate((navPaths.home)); }}>
                            {t("navigation.logout")}
                          </Button>
                        </div>
                      </div>
                    ) : (
                      <div className="space-y-4">
                        <Button onClick={login} className="justify-center inline-block">{t("navigation.login")}</Button>
                        <div className="space-y-1">
                          <p>Login to the BOOM Gaming Guild to Play, Compete and Earn!</p>
                        </div>
                      </div>
                    )}
                    <div className="w-full flex justify-between">
                      <a className="text-sm cursor-pointer absolute bottom-0 pl-4" onClick={() => handleTosClick()}>
                        {t("footer.tos")}
                      </a>
                      <a className="text-sm cursor-pointer absolute bottom-0 right-0 pr-10" onClick={() => handlePPClick()}>
                        {t("footer.privacy-policy")}
                      </a>
                    </div>
                  </div>
                </SideBar>

                {session && (
                  <div className="-mr-2 flex gap-4 md:hidden">
                    <Disclosure.Button
                      className={cx(
                        "inline-flex items-center justify-center rounded-md p-2 text-black focus:outline-none focus:ring-0",
                        "text-black dark:text-white",
                      )}
                    >
                      <span className="sr-only">Open main menu</span>
                      {open ? (
                        <XMarkIcon
                          className="block h-6 w-6"
                          aria-hidden="true"
                        />
                      ) : (
                        <Bars3Icon
                          className="block h-6 w-6"
                          aria-hidden="true"
                        />
                      )}
                    </Disclosure.Button>
                  </div>
                )}
              </div>
            </div>
          </div>

          <Disclosure.Panel className="w-full max-w-screen-xl px-8 py-2 md:hidden">
            <div className="flex flex-col space-y-2 pt-2 pb-3 text-lg">
              {session &&
                paths.map(({ name, path }) => (
                  <Disclosure.Button key={name} as={"div"}>
                    <NavLink
                      key={name}
                      className={({ isActive }) =>
                        isActive
                          ? "gradient-text"
                          : "text-black dark:text-white"
                      }
                      to={path}
                      onClick={() => close()}
                    >
                      {name}
                    </NavLink>
                  </Disclosure.Button>
                ))}
            </div>
          </Disclosure.Panel>
        </div>
      )}
    </Disclosure>
  );
};

export default TopBar;
