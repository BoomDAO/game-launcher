import React from "react";
import { useState } from "react";
import ArrowCircleLeftRoundedIcon from '@mui/icons-material/ArrowCircleLeftRounded';
import ArrowCircleRightRoundedIcon from '@mui/icons-material/ArrowCircleRightRounded';
import "../styles/Slider.css";
import "../styles/index.css";
import { sliderImages } from "../locale/en/common.json";

export default function Slider() {
    //add new featured games here
    const [activeImageNum, setCurrent] = useState(0);
    const length = sliderImages.length;
    const nextSlide = () => {
        setCurrent(activeImageNum === length - 1 ? 0 : activeImageNum + 1);
    };
    const prevSlide = () => {
        setCurrent(activeImageNum === 0 ? length - 1 : activeImageNum - 1);
    };
    if (!Array.isArray(sliderImages) || sliderImages.length <= 0) {
        return null;
    }

    React.useEffect(() => {
        const interval = setInterval(() => {
            nextSlide();
        }, 5000);
        return () => clearInterval(interval);
    }, [activeImageNum]);

    return (
        <div>
            <section style={{ position: "relative", justifyContent: "center", alignItems: "center" }}>
                <div style={{ position: "absolute", top: "46%", left: "1rem", userSelect: "none", cursor: "pointer", zIndex: "5", color: "white" }}>
                    <ArrowCircleLeftRoundedIcon onClick={prevSlide} style={{ fontSize: "3rem" }} />
                </div>
                <div className="right" style={{ position: "absolute", top: "46%", right: "1rem", userSelect: "none", cursor: "pointer", zIndex: "5", color: "white" }}>
                    <ArrowCircleRightRoundedIcon onClick={nextSlide} style={{ fontSize: "3rem" }} />
                </div>
                {sliderImages.map((currentSlide, ind) => {
                    return (
                        <div>
                            <div
                                className={ind === activeImageNum ? "currentSlide active" : "currentSlide"}
                                key={currentSlide.url}
                            >
                                <a href={currentSlide.url} className="cursor: pointer" target="_blank">
                                    {ind === activeImageNum && <img src={currentSlide.image} className="h-72 w-full rounded-primary object-cover shadow md:h-96" />}
                                </a>
                            </div>
                        </div>
                    );
                })}
            </section>
        </div>
    );
}