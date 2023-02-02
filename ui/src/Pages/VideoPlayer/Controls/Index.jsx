import { useContext, useEffect, useRef, useState } from "react";
import { useSelector } from "react-redux";
import { skipToken } from "@reduxjs/toolkit/query/react";

import { useHistory, useNavigate } from "react-router-dom";
import { useGetMediaQuery } from "../../../api/v1/media";
import { formatHHMMSS } from "../../../Helpers/utils";
import { VideoPlayerContext } from "../Context";
import SeekBar from "./SeekBar";
import Actions from "./Actions/Index";
import CircleIcon from "../../../assets/Icons/Circle";

import "./Index.scss";

function VideoControls() {
  const video = useSelector((store) => store.video);

  const nameDiv = useRef(null);
  const timeDiv = useRef(null);

  const { seekTo, overlay } = useContext(VideoPlayerContext);
  const [visible, setVisible] = useState(true);

  const { data: media } = useGetMediaQuery(
    video.mediaID ? video.mediaID : skipToken
  );

  useEffect(() => {
    if (!overlay) return;

    overlay.style.background = visible
      ? "linear-gradient(to top, #000, transparent 30%)"
      : "unset";
  }, [overlay, visible]);

  const navigate = useHistory();
  const back = () => {
    navigate.goBack();
  }


  return (

    <div className={`videoControls ${visible}`}>
      <div onClick={back} className={`back ${visible}`}><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24"><path fill="none" d="M0 0h24v24H0z"/><path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636z"/></svg></div>
      <div className="name" ref={nameDiv}>
        <p>{media && media.name}</p>
        {media && media.episode && (
          <div className="season-ep">
            <p>S{media && media.season}</p>
            <CircleIcon />
            <p>E{media && media.episode}</p>
          </div>
        )}
      </div>
      <div className="time" ref={timeDiv}>
        <p>{formatHHMMSS(video.currentTime)}</p>
        <CircleIcon />
        <p>{formatHHMMSS(video.duration)}</p>
      </div>
      <SeekBar
        seekTo={seekTo}
        nameRef={nameDiv.current}
        timeRef={timeDiv.current}
      />
      <Actions setVisible={setVisible} seekTo={seekTo} />
    </div>
  );
}

export default VideoControls;
