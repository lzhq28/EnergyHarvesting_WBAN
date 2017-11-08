function PdB = mw2dBm( power )
%dBm2mw 将dBm单位的功率转化为mw单位
    PdB = 10.*log10(power);
end

