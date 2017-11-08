function plr = calPLR(tranPower, tranRate, packetSize, PL_Fr, shadow_cur, Channel)
% PLR：计算丢包率
    snr = power(10,(mw2dBm(tranPower)-PL_Fr-shadow_cur-Channel.PNoise)./10).* (Channel.Bandwidth./tranRate); %计算bit信噪比
    PbD = 0.5.*exp(-snr); % 经过DBPSK后的比特错误率
    PbB = PbD - PbD.*power((1-PbD),(Channel.BCH_n-1)); %计算经过信道编码BCH后的比特错误率
    plr = 1 - power((1-PbB),packetSize); %丢包率
end
