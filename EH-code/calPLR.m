function plr = calPLR(tranPower, tranRate, packetSize, PL_Fr, shadow_cur, Channel)
% PLR�����㶪����
    snr = power(10,(mw2dBm(tranPower)-PL_Fr-shadow_cur-Channel.PNoise)./10).* (Channel.Bandwidth./tranRate); %����bit�����
    PbD = 0.5.*exp(-snr); % ����DBPSK��ı��ش�����
    PbB = PbD - PbD.*power((1-PbD),(Channel.BCH_n-1)); %���㾭���ŵ�����BCH��ı��ش�����
    plr = 1 - power((1-PbB),packetSize); %������
end
