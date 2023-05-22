import React from "react";
import { useState } from "react";
import ArrowCircleLeftRoundedIcon from '@mui/icons-material/ArrowCircleLeftRounded';
import ArrowCircleRightRoundedIcon from '@mui/icons-material/ArrowCircleRightRounded';

export default function Slider() {
    //add new featured games here
    const sliderImages = [
        {
            image: "/banner.png",
            url: "https://5iuic-ryaaa-aaaal-ack7a-cai.raw.icp0.io/",

        },
        {
            image: "/game-1.png",
            url: "https://fsowo-7aaaa-aaaal-acdxa-cai.raw.icp0.io/",
        },
        {
            image: "/game-2.png",
            url: "https://edeir-hiaaa-aaaal-acdsq-cai.raw.icp0.io/",
        },
    ];
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
    return (
        <div>
            <section style={{ position: "relative", justifyContent: "center", alignItems: "center" }}>
                <div className="left" style={{ position: "absolute", top: "46%", left: "1rem", userSelect: "none", cursor: "pointer", zIndex: "5", color: "white" }}>
                    <ArrowCircleLeftRoundedIcon onClick={prevSlide} style={{ fontSize: "3rem" }} />
                </div>
                <div className="right" style={{ position: "absolute", top: "46%", right: "1rem", userSelect: "none", cursor: "pointer", zIndex: "5", color: "white" }}>
                    <ArrowCircleRightRoundedIcon onClick={nextSlide} style={{ fontSize: "3rem" }} />
                </div>
                {sliderImages.map((currentSlide, ind) => {
                    return (
                        <div
                            className={ind === activeImageNum ? "currentSlide active" : "currentSlide"}
                            key={ind}
                        >
                            <a href={currentSlide.url} className="cursor: pointer" target="_blank">
                                {ind === activeImageNum && <img src={currentSlide.image} className="h-72 w-full rounded-primary object-cover shadow md:h-96" />}
                            </a>
                        </div>
                    );
                })}
            </section>
        </div>
    );
}