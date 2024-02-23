import { useTranslation } from "react-i18next";
import Divider from "./ui/Divider";
import toast from "react-hot-toast";
import Button from "./ui/Button";
import H1 from "./ui/H1";

const Footer = () => {
  const { t } = useTranslation();

  const handleTosClick = () => {
    toast.custom((t) => (
      <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
        <div className="w-3/4 rounded-3xl mb-7 p-0.5 gradient-bg mt-40 inline-block">
          <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
            <p className="text-2xl font-bold">Terms Of Services</p>
            <div className="overflow-y-auto h-64 px-20">
              Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Eu scelerisque felis imperdiet proin. Facilisis magna etiam tempor orci eu lobortis elementum nibh. Arcu vitae elementum curabitur vitae nunc sed velit dignissim. Sed blandit libero volutpat sed cras ornare arcu dui. Eget nunc lobortis mattis aliquam faucibus purus in. Massa vitae tortor condimentum lacinia quis vel. Duis ultricies lacus sed turpis tincidunt. Quisque sagittis purus sit amet volutpat consequat mauris nunc congue. Diam in arcu cursus euismod quis viverra. A iaculis at erat pellentesque adipiscing commodo elit at imperdiet. Netus et malesuada fames ac turpis egestas. Nibh sed pulvinar proin gravida hendrerit lectus a. Pellentesque id nibh tortor id aliquet. Nunc consequat interdum varius sit amet mattis vulputate enim nulla. Commodo elit at imperdiet dui accumsan.

              Sed arcu non odio euismod lacinia at quis. In eu mi bibendum neque egestas congue. Integer malesuada nunc vel risus commodo viverra maecenas accumsan. Arcu odio ut sem nulla pharetra diam sit. Dictumst quisque sagittis purus sit. Scelerisque purus semper eget duis at tellus at urna. At tempor commodo ullamcorper a. Blandit cursus risus at ultrices mi tempus. Sit amet massa vitae tortor condimentum lacinia. Varius duis at consectetur lorem donec. Et odio pellentesque diam volutpat commodo sed egestas egestas. Diam donec adipiscing tristique risus nec. Maecenas sed enim ut sem viverra aliquet eget sit amet. Sed vulputate odio ut enim blandit volutpat maecenas volutpat. Tellus mauris a diam maecenas sed enim ut sem. Posuere morbi leo urna molestie at elementum eu.

              A lacus vestibulum sed arcu non odio. Vitae et leo duis ut diam. Elit scelerisque mauris pellentesque pulvinar. Vestibulum lectus mauris ultrices eros in. Commodo quis imperdiet massa tincidunt nunc pulvinar sapien et. Fames ac turpis egestas integer eget aliquet nibh praesent tristique. Elementum pulvinar etiam non quam lacus suspendisse. Id leo in vitae turpis massa sed. Bibendum neque egestas congue quisque egestas. Urna nec tincidunt praesent semper feugiat nibh sed pulvinar proin. Diam quis enim lobortis scelerisque fermentum. Sed faucibus turpis in eu mi bibendum neque egestas. Turpis massa tincidunt dui ut ornare lectus. Pellentesque diam volutpat commodo sed. Sed sed risus pretium quam vulputate. Cras adipiscing enim eu turpis egestas. Adipiscing diam donec adipiscing tristique risus nec. Sit amet nulla facilisi morbi tempus.

              Eget nullam non nisi est. Arcu risus quis varius quam quisque id. Tortor at auctor urna nunc id cursus metus aliquam. Sociis natoque penatibus et magnis dis parturient. Placerat vestibulum lectus mauris ultrices eros in cursus turpis massa. Feugiat scelerisque varius morbi enim nunc. Mattis ullamcorper velit sed ullamcorper morbi tincidunt. Volutpat blandit aliquam etiam erat velit scelerisque. Facilisis volutpat est velit egestas dui id. Lectus urna duis convallis convallis tellus id interdum velit laoreet. Neque laoreet suspendisse interdum consectetur libero. Id eu nisl nunc mi ipsum faucibus. Volutpat est velit egestas dui id ornare arcu.

              Eu lobortis elementum nibh tellus molestie nunc. Eu sem integer vitae justo. In pellentesque massa placerat duis ultricies lacus. Eu turpis egestas pretium aenean pharetra magna ac placerat. Amet nisl suscipit adipiscing bibendum est ultricies integer quis. Sed velit dignissim sodales ut eu sem integer vitae justo. Eget aliquet nibh praesent tristique magna. Aliquam nulla facilisi cras fermentum. Arcu cursus vitae congue mauris rhoncus aenean. Et ultrices neque ornare aenean euismod. Lectus vestibulum mattis ullamcorper velit sed ullamcorper morbi tincidunt. Consectetur a erat nam at lectus urna duis convallis. Enim neque volutpat ac tincidunt vitae semper quis lectus.

              Volutpat sed cras ornare arcu dui vivamus arcu. Fermentum posuere urna nec tincidunt praesent. Ante in nibh mauris cursus mattis molestie. Vel fringilla est ullamcorper eget nulla facilisi etiam dignissim. Facilisis leo vel fringilla est ullamcorper eget nulla facilisi. Molestie a iaculis at erat. Ornare arcu dui vivamus arcu. Est ante in nibh mauris cursus mattis molestie a iaculis. Diam sit amet nisl suscipit adipiscing bibendum est ultricies integer. Tempus imperdiet nulla malesuada pellentesque elit eget. Fermentum odio eu feugiat pretium nibh ipsum. Consectetur a erat nam at lectus. Tellus mauris a diam maecenas sed enim. Sed cras ornare arcu dui vivamus arcu felis bibendum ut. Integer quis auctor elit sed vulputate mi. Vitae purus faucibus ornare suspendisse sed nisi lacus. Ultrices eros in cursus turpis. Nisl suscipit adipiscing bibendum est ultricies. At varius vel pharetra vel turpis nunc eget.

              Interdum velit euismod in pellentesque. Convallis tellus id interdum velit laoreet id donec ultrices. Quis varius quam quisque id diam vel quam. Felis donec et odio pellentesque diam volutpat. Velit scelerisque in dictum non consectetur a erat nam at. Nisl vel pretium lectus quam id leo in vitae. Eget mi proin sed libero enim. Enim nunc faucibus a pellentesque sit. Egestas fringilla phasellus faucibus scelerisque eleifend donec pretium. In ante metus dictum at tempor. Nunc pulvinar sapien et ligula ullamcorper malesuada. Ornare massa eget egestas purus viverra accumsan in nisl nisi. Fusce id velit ut tortor pretium viverra suspendisse. Laoreet id donec ultrices tincidunt arcu non sodales. Tempus urna et pharetra pharetra massa. Arcu felis bibendum ut tristique et egestas. Nunc mattis enim ut tellus elementum sagittis vitae et leo. Adipiscing vitae proin sagittis nisl rhoncus mattis rhoncus urna neque. Duis tristique sollicitudin nibh sit amet commodo nulla facilisi nullam.

              Egestas congue quisque egestas diam in arcu. Enim neque volutpat ac tincidunt vitae semper. Sed faucibus turpis in eu mi bibendum neque egestas congue. Maecenas ultricies mi eget mauris pharetra et ultrices neque ornare. Sed pulvinar proin gravida hendrerit lectus. Convallis a cras semper auctor neque vitae tempus quam pellentesque. Integer eget aliquet nibh praesent tristique magna sit amet. Lectus quam id leo in vitae turpis massa sed. Viverra maecenas accumsan lacus vel facilisis volutpat est. Ut porttitor leo a diam sollicitudin tempor.

              Tempus iaculis urna id volutpat lacus laoreet non. Faucibus vitae aliquet nec ullamcorper sit amet. Volutpat consequat mauris nunc congue nisi vitae. Mauris augue neque gravida in fermentum et sollicitudin ac. Dignissim diam quis enim lobortis scelerisque fermentum dui faucibus in. Massa tempor nec feugiat nisl pretium fusce id. Dignissim enim sit amet venenatis. Ornare quam viverra orci sagittis. Sodales ut etiam sit amet nisl purus. Eu tincidunt tortor aliquam nulla facilisi cras. Non pulvinar neque laoreet suspendisse interdum consectetur.

              Tortor condimentum lacinia quis vel eros donec ac. Suspendisse faucibus interdum posuere lorem ipsum dolor. Sed elementum tempus egestas sed sed risus pretium. Turpis egestas integer eget aliquet nibh praesent tristique magna sit. Platea dictumst vestibulum rhoncus est pellentesque elit ullamcorper. Ac odio tempor orci dapibus ultrices in iaculis nunc. Quis hendrerit dolor magna eget est. Mi in nulla posuere sollicitudin aliquam ultrices sagittis. Ultrices eros in cursus turpis. Lacus sed turpis tincidunt id aliquet. Eu augue ut lectus arcu bibendum. Amet massa vitae tortor condimentum. Enim diam vulputate ut pharetra sit amet aliquam id diam. Donec ultrices tincidunt arcu non. Risus commodo viverra maecenas accumsan lacus vel facilisis volutpat est. Duis at tellus at urna condimentum mattis. Viverra nibh cras pulvinar mattis nunc sed. Nulla porttitor massa id neque aliquam vestibulum morbi blandit.
            </div>
            <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
          </div>
        </div>
      </div>
    ));
  };

  return (
    <>
      <Divider className="mb-6" />
      <div className="flex flex-col-reverse justify-between gap-2 text-sm md:flex-row">
        <p>{t("footer.copyright")}</p>
        <div className="flex items-center gap-4">
          <a className="gradient-text text-lg font-semibold cursor-pointer" onClick={() => handleTosClick()}>
            {t("footer.tos")}
          </a>
          <p className="gradient-text text-lg font-semibold">
            {t("footer.follow")}:
          </p>
          <div className="flex gap-3">
            <a href="https://twitter.com/boomdaosns" target="_blank">
              <img
                src="/twitter.svg"
                alt="twitter"
                className="cursor-pointer"
              />
            </a>
            <a href="https://github.com/BoomDAO" target="_blank">
              <img style={{ width: 24 }} src="/github.svg" alt="medium" className="cursor-pointer" />
            </a>
            <a href="https://discord.com/invite/fPVqZkQ6x2" target="_blank">
              <img style={{ width: 24 }} src="/discord.svg" alt="medium" className="cursor-pointer" />
            </a>
          </div>
        </div>
      </div>
    </>
  );
};

export default Footer;
