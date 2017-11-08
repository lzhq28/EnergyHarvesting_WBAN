function [PLR_ave,P_sum] = calAvePLR(sigma, miu_dB, packet_length, BCH_n)
% ����ƽ��������
% ����;   
%   sigma ��������ȵı�׼��
%   miu_dB ��������ȵ�ƽ��ֵ
%   packet_length ���ݰ��ĳ���
%   BCH_n BCH����ĳ���
% �����
%   PLR_ave ƽ��������
%   P_sum ʹ����ɢ�ķ����õ��ı�������ȷֲ��ܵĸ��ʺͣ���Ҫ�ƽ�1��
    [snr, snr_interval] = findSNRInterval(sigma, miu_dB, packet_length, BCH_n);
    Prb =((10/log(10))./(power(2*pi,0.5).*sigma.*snr).*exp(-power((10*log10(snr)-miu_dB),2)./(2*power(sigma,2)))); % ���ڸ���snr�µĸ���
    PLR = 1-power((1-0.5*exp(-snr)+0.5*exp(-snr).*power((1-0.5*exp(-snr)),BCH_n-1)),packet_length); %����snr�µĶ�����
    P_sum = sum(Prb.*snr_interval);
    PLR_ave = sum(Prb.*PLR.*snr_interval);
    
    function [snr, snr_interval] = findSNRInterval(sigma, miu_dB, packet_length, BCH_n)
    % �ҵ����ʵ�snr��������ֵ����Сֵ����,����ú��������findMiuThreshold������
    % ����;   
    %   sigma ��������ȵı�׼��
    %   miu_dB ��������ȵ�ƽ��ֵ
    %   packet_length ���ݰ��ĳ���
    %   BCH_n BCH����ĳ���
    % �����
    %   snr ��������ȵ���ɢֵ
    %   snr_interval �����������ɢ���еļ���������ۼӼ���

        snr_range = [0.00000001,0.0000001,0.000001, 0.00001, 0.0001, 0.001, 0.01,0.1, 1, 10, 50, 100, 500, 1000, 5000, 10000, 50000,100000];
        Prb =((10/log(10))./(power(2*pi,0.5).*sigma.*snr_range).*exp(-power((10*log10(snr_range)-miu_dB),2)./(2*power(sigma,2)))); % ����snr�ĸ���
        PLR = 1-power((1-0.5*exp(-snr_range)+0.5*exp(-snr_range).*power((1-0.5*exp(-snr_range)),BCH_n-1)),packet_length); %����snr�µĶ�����
        tmp_PLR_r = Prb;
        PLR_r_th = 10^(-40);
        ind=find(tmp_PLR_r> PLR_r_th);
        if size(ind,2)>1
            snr_min = snr_range(max(1,ind(1)-1));
            %snr_max = snr_range(min(size(snr_range,2),ind(end)+1));
            snr_max = dBm2mw(miu_dB + 4*sigma);
            if snr_max > 10000 % ��Щ�������Ǿ���ֵ
                snr_max = 10000;
            end
            if snr_min < 0.0001 %����snr_max̫���ʹ�ýϴ��������
                snr_interval= 0.0001;
            else
                snr_interval = 0.001;
            end
            snr = snr_min:snr_interval:snr_max;
        else
            disp('Error:snr range is not enough');
        end
    end
end 