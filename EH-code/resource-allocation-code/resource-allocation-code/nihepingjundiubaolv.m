n=63;
step=5;

syms r_b
P_r_b=((10/log(10))./(power(2*pi,0.5).*kesi.*r_b).*exp(-power((10*log10(r_b)-miu_b_dB),2)./(2*power(kesi,2))));

P_b=1-power((1-0.5*exp(-r_b)+0.5*exp(-r_b)*power((1-0.5*exp(-r_b)),n-1)),length)
subs(P_b,r_b,0.1)