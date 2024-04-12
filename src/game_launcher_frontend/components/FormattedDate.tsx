import { useTranslation } from "react-i18next";
import Divider from "./ui/Divider";

interface date {
    days: string;
    hrs: string;
    mins: string;
}

const FormattedDate = ({
    days,
    hrs,
    mins
}: date) => {
    const { t } = useTranslation();

    return (
        <>
            <div className="w-1/2">
                <div className="flex justify-between text-3xl">
                    <div>
                        <p className="font-semibold">{days}</p>
                        <p className="text-xs text-center">DAYS</p>
                    </div>
                    <div>
                        <p className="font-semibold pl-1">{hrs}</p>
                        <p className="text-xs text-center">HOURS</p>
                    </div>
                    <div>
                        <p className="font-semibold pl-1">{mins}</p>
                        <p className="text-xs text-center">MINUTES</p>
                    </div>
                </div>
            </div>
        </>
    );
};

export default FormattedDate;