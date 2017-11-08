function miu=binarySearch(miuMin,miuMax,kesi,length,avePLRth,delta)

%% binarySearch��ʹ�ö��ַ���ʹ����С�������ҵ��ﵽƽ�����������޵�ƽ�������
%���룺
%miuMin�����õĲ��ҷ�Χ����
%miuMax�����õĲ��ҷ�Χ����
%kesi:����ȵ����
%length:Ϊ����bit��
%avePLRth��Ҫ�ﵽ��ƽ��������
%delta������ֵ����ʵֵ֮������þ���ʱȷ���ҵ�

%���ȶԱ߽���м���

tic
left=miuMin;
right=miuMax;
n=63;
step=5;

interval=0.001;
max_r_b=100000;
min_r_b=0.001;
x= min_r_b:interval:max_r_b;
syms r_b
% P_b=1-power((1-0.5*exp(-r_b)+0.5*exp(-r_b)*power((1-0.5*exp(-r_b)),n-1)),length)
     
ifelse=@(a,b,c)(a~=0)*b+(a==0)*c;
while 1    
        mid=(left+right)/2;
        miu_b_dB=mid;
        %% ����һ��ʹ��͹��������ʽ�ķ��������ַ������ںܴ�����
%         P_r_b=((10/log(10))./(power(2*pi,0.5).*kesi.*r_b).*exp(-power((10*log10(r_b)-miu_b_dB),2)./(2*power(kesi,2))));
%         tmpPr=(length.*log(1-0.5*exp(-r_b)+0.5*exp(-r_b)*power((1-0.5*exp(-r_b)),n-1))*P_r_b);
%  
%         tmp=double((int(tmpPr,r_b,0,1000)));
%         tmpAvePLRth=1-exp(tmp);
        %% ��������ʹ����ɢֵ���Ƶķ���

    P_r_b=((10/log(10))./(power(2*pi,0.5).*kesi.*r_b).*exp(-power((10*log10(r_b)-miu_b_dB),2)./(2*power(kesi,2))));
    P_b=1-power((1-0.5*exp(-r_b)+0.5*exp(-r_b)*power((1-0.5*exp(-r_b)),n-1)),length);

    test_P_b=subs(P_b,r_b,x);    
    test_P_r_b=subs(P_r_b,r_b,x);
    if abs(sum(test_P_r_b.*interval)-1)>0.05 %��
        disp(['error:you should turn up the max_r_b'])
        return
    end
    tmpAvePLRth=sum(test_P_b.*test_P_r_b.*interval)      
        
        if (abs(tmpAvePLRth-avePLRth)<=delta)
            miu=miu_b_dB;
            disp(['�����(miu,kesi):(',num2str(miu),',',num2str(kesi),'),tmpAvePLRth:',num2str(tmpAvePLRth),',avePLRth:',num2str(avePLRth)])
            return;
        else
            if abs(right-left)>=delta %������Ҽ������delta��˵��ֻ����ʱδ�ҵ������������޸ı߽�
                if tmpAvePLRth > avePLRth
                    left=mid;
                elseif tmpAvePLRth < avePLRth
                    right=mid;             
                end;    
            else
                if tmpAvePLRth > avePLRth
                    right=miuMax+step;
                elseif tmpAvePLRth < avePLRth
                    left=ifelse(miuMin-step>0,miuMin-step,0);
                end;
            end
            
        end;        
end
 toc
