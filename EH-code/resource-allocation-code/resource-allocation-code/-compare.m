figureShow=1
 %��ʼ��ͳ�ƽ������
 statistics_P_out=0;%����ͳ���жϽ��
 statistics_PLR=0;  %����ͳ�ƶ�����
 statistics_Delay=0; %����ͳ��ʱ��
 statistics_Num_Infeasible=0;%����ͳ���Ż������޷����������
 contrast_statistics_P_out=0;
 contrast_statistics_PLR=0;
 contrast_statistics_Delay=0;
 C2_statistics_P_out=0;
 C2_statistics_PLR=0;
 C2_statistics_Delay=0;
 
 for m=1:N_ch     
     %% ���ӶԱ�����
     if m<= ProbPosture(1)*N_ch
         pos=1;
     elseif m<=(ProbPosture(1)+ProbPosture(2))*N_ch
         pos=2;
     else 
         pos=3;
     end;
      X_Shadow_Real=(NodeKese(pos,:)'.*randn(N_Node,1));
      Em_Num_Packet{m}=poissrnd(Emergency_SourceRate_Ave).*T_Frame;%ÿһ֡������ʵ�ʲ�������
      %% ������ֵ������ɢ��
      final_Power{m}=Result_Power{m};
      final_Rate{m}=power(2,floor(log2(Result_Rate{m}./R_basic)))*R_basic;%����ȡ����ȡ�ý�С����������
      final_Actual_time{m}(1:2:2*N_Node,1)=Normal_SourceRate.*T_Frame./final_Rate{m}(1:2:2*N_Node);%����ͨ��
      final_Actual_time{m}(2:2:2*N_Node,1)=Em_Num_Packet{m}./final_Rate{m}(2:2:2*N_Node);%����ͨ��
      %������ɢ������������ʣ���ʱ϶�������޸�---��ʱ�����ǣ�ֱ���������Ϸ�ӳ     
      final_Scheduled_time{m}(1:2:2*N_Node,1)=ceil( final_Actual_time{m}(1:2:2*N_Node,1)/T_Slot)*T_Slot;%����ȡ��  
      final_Scheduled_time{m}(2:2:2*N_Node,1)=ceil( Result_Rate{m}(2:2:2*N_Node,1).*Result_time{m}(2:2:2*N_Node,1)./final_Rate{m}(2:2:2*N_Node,1)./T_Slot)*T_Slot;%����ȡ��      
      
      
      
      %%���ܣ�Ҳ����Լ��:�����ʣ�ʱ�ӣ��ж���
      %�ж���
      final_P_out{m}(1:2:2*N_Node,1)=qfunc(10*log10(final_Power{m}(1:2:2*N_Node))+NodeMiuPosture(pos,:)'-P_Sensitivity);
      final_P_out{m}(2:2:2*N_Node,1)=qfunc(10*log10(final_Power{m}(2:2:2*N_Node))+NodeMiuPosture(pos,:)'-P_Sensitivity);
      statistics_P_out=statistics_P_out+final_P_out{m};%�ۼӽ��
      %������
      final_SNR_b{m}(1:2:2*N_Node,1)=power(10,(10*log10(final_Power{m}(1:2:2*N_Node))+NodeMiuPosture(pos,:)'-final_X_Shadow{m}- PNoise)/10).*(BandWidth./final_Rate{m}(1:2:2*N_Node));
      final_SNR_b{m}(2:2:2*N_Node,1)=power(10,(10*log10(final_Power{m}(2:2:2*N_Node))+NodeMiuPosture(pos,:)'-final_X_Shadow{m}-PNoise)/10).*(BandWidth./final_Rate{m}(2:2:2*N_Node));
      final_P_b_DBPSK{m}=0.5*exp(-final_SNR_b{m});
      final_P_b_BCH{m}=final_P_b_DBPSK{m}-final_P_b_DBPSK{m}.*power((1-final_P_b_DBPSK{m}),n_BCH_PSDU-1);%-(n_BCH_PSDU-1)*power(final_P_b_DBPSK{m},2).*power((1-final_P_b_DBPSK{m}),n_BCH_PSDU-2);
      final_PLR{m}(1:2:2*N_Node,1)=1-power((1-final_P_b_BCH{m}(1:2:2*N_Node,1)),Normal_L_packet);
      final_PLR{m}(2:2:2*N_Node,1)=1-power((1-final_P_b_BCH{m}(2:2:2*N_Node,1)),Emergency_L_packet);
      final_Energy_Cons{m}=final_Actual_time{m}.*((a+1).*final_Power{m}+b);  %�����ڸ���֡���ܺ� 
      statistics_PLR= statistics_PLR+final_PLR{m};%�ۼӶ�����
      %ʱ��
      tmp_Lamta=Normal_SourceRate.*T_Frame./Normal_L_packet;
      tmp_Mue=final_Rate{m}(1:2:2*N_Node,1).*final_Scheduled_time{m}(1:2:2*N_Node,1)./Normal_L_packet;
      final_Delay{m}(1:2:2*N_Node,1)=T_Frame+Normal_L_packet./final_Rate{m}(1:2:2*N_Node,1)+tmp_Lamta.*(Normal_Kesee_A+Normal_Kesee_B)./(2*(1-tmp_Lamta./tmp_Mue)).*T_Frame;
      %final_Wait_time{m}(1:2:2*N_Node,1)=T_Frame+Normal_L_packet./final_Rate{m}(1:2:2*N_Node,1)+(Normal_SourceRate.*T_Frame./Normal_L_packet).*(Normal_Kesee_A+Normal_Kesee_B).*T_Frame./(2*(1-(Normal_SourceRate.*T_Frame)./(Result_Rate{m}(1:2:2*N_Node,1).*Result_time{m}(1:2:2*N_Node,1))))
      tmp_Lamta=(Emergency_SourceRate_Ave.*T_Frame./Emergency_L_packet);
      tmp_Mue=final_Rate{m}(2:2:2*N_Node,1).*final_Scheduled_time{m}(2:2:2*N_Node,1)./Emergency_L_packet;
      final_Delay{m}(2:2:2*N_Node,1)=T_Frame+Emergency_L_packet./final_Rate{m}(2:2:2*N_Node,1)+ (tmp_Lamta+tmp_Lamta.*power(tmp_Mue,2).*Emergency_Kesee_B)./(2*(power(tmp_Mue,2)-tmp_Lamta.*tmp_Mue))*T_Frame;
      statistics_Delay=statistics_Delay+final_Delay{m};
      
      %% �Ա����������transmission power control in body area sensor network for healthcare monitoring��
          a_d=0.8;
          a_u=0.6;
          T_L=-57;
          T_H=-50;
          C2_Rate{m}(1:2*N_Node,1)=DataRate(4);
          if m==1
              C2_Power{m}=[1;1;1;1;1;1;1;1;1;1];
              aveRSSI(1:2:2*N_Node,1)=10*log10(C2_Power{1}(1:2:2*N_Node,1))+NodeMiuPosture(pos,:)'-final_X_Shadow{m};
              aveRSSI(2:2:2*N_Node,1)=10*log10(C2_Power{1}(2:2:2*N_Node,1))+NodeMiuPosture(pos,:)'-final_X_Shadow{m};
          else
              C2_Power{m}=C2_Power{m-1};
              curRSSI(1:2:2*N_Node,1)=10*log10(C2_Power{1}(1:2:2*N_Node,1))+NodeMiuPosture(pos,:)'-final_X_Shadow{m};
              curRSSI(2:2:2*N_Node,1)=10*log10(C2_Power{1}(2:2:2*N_Node,1))+NodeMiuPosture(pos,:)'-final_X_Shadow{m};
              index1= find(curRSSI<=aveRSSI);
              if size(index1,1)~=0
                aveRSSI(index1,1)=a_d*curRSSI(index1,1)+(1-a_d)*aveRSSI(index1,1);
              end;

              index2=find(curRSSI>aveRSSI);
              if size(index2,1)~=0
                  aveRSSI(index2,1)=a_u*curRSSI(index2,1)+(1-a_d)*aveRSSI(index2,1);
              end;

              index3=find(aveRSSI<T_L);
              if size(index3,1)~=0
                  C2_Power{m}(index3,1)=C2_Power{m}(index3,1).*2; %���ʼӱ�
                  index4=find(C2_Power{m}>P_tx_max);              
                  if ~isempty(index4)
                      C2_Power{m}(index4,1)=P_tx_max;              
                  end;
              end;
              index5=find(aveRSSI>T_H);
              if ~isempty(index5)
                  C2_Power{m}(index5,1)=C2_Power{m}(index5,1)./2;
                  index6=find(C2_Power{m}<P_tx_min);
                  if ~isempty(index6)
                      C2_Power{m}(index6,1)=P_tx_min;
                  end;
              end;             
             
          end;
          
          %����Ա�����2������
      C2_Actual_time{m}(1:2:2*N_Node,1)=Normal_SourceRate.*T_Frame./C2_Rate{m}(1:2:2*N_Node,1);%����ͨ��
      C2_Actual_time{m}(2:2:2*N_Node,1)=Em_Num_Packet{m}./C2_Rate{m}(2:2:2*N_Node,1);%����ͨ��
      C2_Scheduled_time{m}(1:2:2*N_Node,1)=ceil(C2_Actual_time{m}(1:2:2*N_Node,1)/T_Slot)*T_Slot;%����ȡ�� Normal_SourceRate.*T_Frame./ DataRate(2);
      C2_Scheduled_time{m}(2:2:2*N_Node,1)=ceil(Emergency_SourceRate_Ave.*T_Frame./ C2_Rate{m}(2:2:2*N_Node,1)./T_Slot)*T_Slot;%Emergency_SourceRate_Ave.*T_Frame./  DataRate(2);
      C2_P_out{m}(1:2:2*N_Node,1)=qfunc(10*log10(C2_Power{m}(1:2:2*N_Node))+NodeMiuPosture(pos,:)'-P_Sensitivity);
      C2_P_out{m}(2:2:2*N_Node,1)=qfunc(10*log10(C2_Power{m}(2:2:2*N_Node))+NodeMiuPosture(pos,:)'-P_Sensitivity);
      C2_statistics_P_out=C2_statistics_P_out+C2_P_out{m};%�ۼӽ��
          
      C2_SNR_b{m}(1:2:2*N_Node,1)=power(10,(10*log10(C2_Power{m}(1:2:2*N_Node))+NodeMiuPosture(pos,:)'-final_X_Shadow{m}- PNoise)/10).*(BandWidth./C2_Rate{m}(1:2:2*N_Node));
      C2_SNR_b{m}(2:2:2*N_Node,1)=power(10,(10*log10(C2_Power{m}(2:2:2*N_Node))+NodeMiuPosture(pos,:)'-final_X_Shadow{m}- PNoise)/10).*(BandWidth./C2_Rate{m}(2:2:2*N_Node));
      C2_P_b_DBPSK{m}=0.5*exp(-C2_SNR_b{m});
      C2_P_b_BCH{m}=C2_P_b_DBPSK{m}-C2_P_b_DBPSK{m}.*power((1-C2_P_b_DBPSK{m}),n_BCH_PSDU-1);%-(n_BCH_PSDU-1)*power(C2_P_b_DBPSK{m},2).*power((1-C2_P_b_DBPSK{m}),n_BCH_PSDU-2);
      C2_PLR{m}(1:2:2*N_Node,1)=1-power((1-C2_P_b_BCH{m}(1:2:2*N_Node,1)),Normal_L_packet);
      C2_PLR{m}(2:2:2*N_Node,1)=1-power((1-C2_P_b_BCH{m}(2:2:2*N_Node,1)),Emergency_L_packet);
      C2_Energy_Cons{m}=C2_Actual_time{m}.*((a+1).*C2_Power{m}+b);  %�����ڸ���֡���ܺ� 
      C2_statistics_PLR= C2_statistics_PLR+C2_PLR{m}; %�ۼ��ж���
       
      tmp_Lamta=Normal_SourceRate.*T_Frame./Normal_L_packet;
      tmp_Mue=(1-C2_PLR{m}(1:2:2*N_Node,1)).*C2_Rate{m}(1:2:2*N_Node,1).*C2_Scheduled_time{m}(1:2:2*N_Node,1)./Normal_L_packet; %(1-C2_PLR{m}(1:2:2*N_Node,1)).*
      C2_Delay{m}(1:2:2*N_Node,1)=T_Frame+Normal_L_packet./C2_Rate{m}(1:2:2*N_Node,1)+tmp_Lamta.*(Normal_Kesee_A+Normal_Kesee_B)./(2*(1-tmp_Lamta./tmp_Mue)).*T_Frame;
      %final_Wait_time{m}(1:2:2*N_Node,1)=T_Frame+Normal_L_packet./final_Rate{m}(1:2:2*N_Node,1)+(Normal_SourceRate.*T_Frame./Normal_L_packet).*(Normal_Kesee_A+Normal_Kesee_B).*T_Frame./(2*(1-(Normal_SourceRate.*T_Frame)./(Result_Rate{m}(1:2:2*N_Node,1).*Result_time{m}(1:2:2*N_Node,1))))
      tmp_Lamta=(Emergency_SourceRate_Ave.*T_Frame./Emergency_L_packet);
      tmp_Mue=C2_Rate{m}(2:2:2*N_Node,1).*C2_Scheduled_time{m}(2:2:2*N_Node,1)./Emergency_L_packet;
      C2_Delay{m}(2:2:2*N_Node,1)=T_Frame+Emergency_L_packet./C2_Rate{m}(2:2:2*N_Node,1)+ (tmp_Lamta+tmp_Lamta.*power(tmp_Mue,2).*Emergency_Kesee_B)./(2*(power(tmp_Mue,2)-tmp_Lamta.*tmp_Mue))*T_Frame;
      C2_statistics_Delay=C2_statistics_Delay+C2_Delay{m} ;
 
 
 
      
      %%�Ա�����
      %%�����еĽڵ���ù̶��ķ��书��1mw�͹̶���ʱ϶���䡣
      contrast_Power{m}(1:2*N_Node,1)=[1;1;1;1;1;1;1;1;1;1];%����̶��ķ��书��Ϊ1mw
      contrast_Rate{m}(1:2:2*N_Node,1)=DataRate(3);
      contrast_Rate{m}(2:2:2*N_Node,1)=DataRate(3);
      contrast_Actual_time{m}(1:2:2*N_Node,1)=Normal_SourceRate.*T_Frame./contrast_Rate{m}(1:2:2*N_Node,1);%����ͨ��
      contrast_Actual_time{m}(2:2:2*N_Node,1)=Em_Num_Packet{m}./contrast_Rate{m}(2:2:2*N_Node,1);%����ͨ��
      contrast_Scheduled_time{m}(1:2:2*N_Node,1)=ceil(contrast_Actual_time{m}(1:2:2*N_Node,1)/T_Slot)*T_Slot;%����ȡ�� Normal_SourceRate.*T_Frame./ DataRate(2);
      contrast_Scheduled_time{m}(2:2:2*N_Node,1)=ceil(Emergency_SourceRate_Ave.*T_Frame./ DataRate(3)./T_Slot)*T_Slot;%Emergency_SourceRate_Ave.*T_Frame./  DataRate(2);
      contrast_P_out{m}(1:2:2*N_Node,1)=qfunc(10*log10(contrast_Power{m}(1:2:2*N_Node))+NodeMiuPosture(pos,:)'-P_Sensitivity);
      contrast_P_out{m}(2:2:2*N_Node,1)=qfunc(10*log10(contrast_Power{m}(2:2:2*N_Node))+NodeMiuPosture(pos,:)'-P_Sensitivity);
      contrast_statistics_P_out=contrast_statistics_P_out+contrast_P_out{m};%�ۼӽ��
      
      contrast_SNR_b{m}(1:2:2*N_Node,1)=power(10,(10*log10(contrast_Power{m}(1:2:2*N_Node))+NodeMiuPosture(pos,:)'-final_X_Shadow{m}- PNoise)/10).*(BandWidth./contrast_Rate{m}(1:2:2*N_Node));
      contrast_SNR_b{m}(2:2:2*N_Node,1)=power(10,(10*log10(contrast_Power{m}(2:2:2*N_Node))+NodeMiuPosture(pos,:)'-final_X_Shadow{m}- PNoise)/10).*(BandWidth./contrast_Rate{m}(2:2:2*N_Node));
      contrast_P_b_DBPSK{m}=0.5*exp(-contrast_SNR_b{m});
      contrast_P_b_BCH{m}=contrast_P_b_DBPSK{m}-contrast_P_b_DBPSK{m}.*power((1-contrast_P_b_DBPSK{m}),n_BCH_PSDU-1);%-(n_BCH_PSDU-1)*power(contrast_P_b_DBPSK{m},2).*power((1-contrast_P_b_DBPSK{m}),n_BCH_PSDU-2);
      contrast_PLR{m}(1:2:2*N_Node,1)=1-power((1-contrast_P_b_BCH{m}(1:2:2*N_Node,1)),Normal_L_packet);
      contrast_PLR{m}(2:2:2*N_Node,1)=1-power((1-contrast_P_b_BCH{m}(2:2:2*N_Node,1)),Emergency_L_packet);
      contrast_Energy_Cons{m}=contrast_Actual_time{m}.*((a+1).*contrast_Power{m}+b);  %�����ڸ���֡���ܺ� 
      contrast_statistics_PLR= contrast_statistics_PLR+contrast_PLR{m}; %�ۼ��ж���
        
      tmp_Lamta=Normal_SourceRate.*T_Frame./Normal_L_packet;
      tmp_Mue=contrast_Rate{m}(1:2:2*N_Node,1).*contrast_Scheduled_time{m}(1:2:2*N_Node,1)./Normal_L_packet;
      contrast_Delay{m}(1:2:2*N_Node,1)=T_Frame+Normal_L_packet./contrast_Rate{m}(1:2:2*N_Node,1)+tmp_Lamta.*(Normal_Kesee_A+Normal_Kesee_B)./(2*(1-tmp_Lamta./tmp_Mue)).*T_Frame;
      %final_Wait_time{m}(1:2:2*N_Node,1)=T_Frame+Normal_L_packet./final_Rate{m}(1:2:2*N_Node,1)+(Normal_SourceRate.*T_Frame./Normal_L_packet).*(Normal_Kesee_A+Normal_Kesee_B).*T_Frame./(2*(1-(Normal_SourceRate.*T_Frame)./(Result_Rate{m}(1:2:2*N_Node,1).*Result_time{m}(1:2:2*N_Node,1))))
      tmp_Lamta=(Emergency_SourceRate_Ave.*T_Frame./Emergency_L_packet);
      tmp_Mue=contrast_Rate{m}(2:2:2*N_Node,1).*contrast_Scheduled_time{m}(2:2:2*N_Node,1)./Emergency_L_packet;
      contrast_Delay{m}(2:2:2*N_Node,1)=T_Frame+Emergency_L_packet./contrast_Rate{m}(2:2:2*N_Node,1)+ (tmp_Lamta+tmp_Lamta.*power(tmp_Mue,2).*Emergency_Kesee_B)./(2*(power(tmp_Mue,2)-tmp_Lamta.*tmp_Mue))*T_Frame;
      contrast_statistics_Delay=contrast_statistics_Delay+contrast_Delay{m} ;

 end;

%%�Ա����飬����ʾ���
 statistics_P_out=statistics_P_out/N_ch
 statistics_PLR=statistics_PLR/N_ch;
 statistics_Delay=statistics_Delay/N_ch;

 contrast_statistics_P_out=contrast_statistics_P_out/N_ch
 contrast_statistics_Delay=contrast_statistics_Delay/N_ch;
 contrast_statistics_PLR= contrast_statistics_PLR/N_ch;

  C2_statistics_P_out= C2_statistics_P_out/N_ch;
  C2_statistics_Delay=C2_statistics_Delay/N_ch;
  C2_statistics_PLR= C2_statistics_PLR/N_ch;
%%ͳ�ƶԱȽ��
 % ͳ���ж���
  for m=1:N_Node
      
    result_Normal_Show_P_Out(m,1)=statistics_P_out((m-1)*2+1);
    result_Emergency_Show_P_Out(m,1)=statistics_P_out((m-1)*2+2);

    result_Normal_Show_P_Out(m,2)=contrast_statistics_P_out((m-1)*2+1);
    result_Emergency_Show_P_Out(m,2)=contrast_statistics_P_out((m-1)*2+2);  
        
    result_Normal_Show_PLR(m,1)=statistics_PLR((m-1)*2+1);
    result_Emergency_Show_PLR(m,1)=statistics_PLR((m-1)*2+2);
    
    result_Normal_Show_PLR(m,2)=contrast_statistics_PLR((m-1)*2+1);
    result_Emergency_Show_PLR(m,2)=contrast_statistics_PLR((m-1)*2+2);
    result_Normal_Show_PLR(m,3)=C2_statistics_PLR((m-1)*2+1);
    result_Emergency_Show_PLR(m,3)=C2_statistics_PLR((m-1)*2+2);
    
    result_Normal_Show_Delay(m,1)=statistics_Delay((m-1)*2+1);
    result_Emergency_Show_Delay(m,1)=statistics_Delay((m-1)*2+2);
    result_Normal_Show_Delay(m,2)=contrast_statistics_Delay((m-1)*2+1);
    result_Emergency_Show_Delay(m,2)=contrast_statistics_Delay((m-1)*2+2);
    result_Normal_Show_Delay(m,3)=C2_statistics_Delay((m-1)*2+1);
    result_Emergency_Show_Delay(m,3)=C2_statistics_Delay((m-1)*2+2);
    
    
    
    
    
 end;
 

 
 
result_Normal_Show_Energy=zeros(N_Node,3);
result_Emergency_Show_Energy=zeros(N_Node,3);
 for m=1:N_ch
    result_Normal_Show_Energy(:,1)=result_Normal_Show_Energy(:,1)+final_Energy_Cons{m}(1:2:2*N_Node);
    result_Normal_Show_Energy(:,2)=result_Normal_Show_Energy(:,2)+ contrast_Energy_Cons{m}(1:2:2*N_Node);
    result_Normal_Show_Energy(:,3)=result_Normal_Show_Energy(:,3)+ C2_Energy_Cons{m}(1:2:2*N_Node);
    
    result_Emergency_Show_Energy(:,1)=result_Emergency_Show_Energy(:,1)+final_Energy_Cons{m}(2:2:2*N_Node);
    result_Emergency_Show_Energy(:,2)=result_Emergency_Show_Energy(:,2)+contrast_Energy_Cons{m}(2:2:2*N_Node);
    result_Emergency_Show_Energy(:,3)=result_Emergency_Show_Energy(:,3)+C2_Energy_Cons{m}(2:2:2*N_Node);
    
    
    
    
 end;
 
 
 
 %% �Ա����������transmission power control in body area sensor network for healthcare monitoring��
%  

%����ʵ����
% fileName=datestr(now,30);
% save (strcat(fileName,'-Nch-',num2str(N_ch),'-yalmip-continue'))

%% ��ʾ���
if figureShow==1
 %�ж���
%      figure(1)
%      subplot(211)
%      bar(result_Normal_Show_P_Out)
%      title('Normal-Pout')
%      legend('Optimized','Decided','Location','NorthWest')
%      xlabel('Node no.');
%      ylabel('P-Out of normal traffic(%)')
% 
%      subplot(212)
%      bar(result_Emergency_Show_P_Out)
%      title('Emergency-Pout')
%      legend('Optimized','Decided','Location','NorthWest')
%      xlabel('Node no.');
%      ylabel('P-Out of Emergency Traffic(%)')

     %������
     figure(2)
     subplot(211)
     bar(result_Normal_Show_PLR)
     title('Normal-PLR')
     xlabel('Node no.');
     ylabel('PLR of Normal Packets');
     legend('Optimized','Decided','TPC1','Location','NorthWest')
     subplot(212)
     bar(result_Emergency_Show_PLR)
     title('Emergency-PLR')
     legend('Optimized','Decided','TPC1','Location','NorthWest')
     xlabel('Node no.');
     ylabel('PLR of Emergency Packets');

      %ʱ��
     figure(3)
     subplot(211)
     bar(result_Normal_Show_Delay)
     title('Delay of Normal Packets ')
     legend('Optimized','Decided','TPC1','Location','NorthWest')
     xlabel('Node no.');
     ylabel('Delay of Normal Packets(ms)');
     subplot(212)
     bar(result_Emergency_Show_Delay)
     title('Delay of Emergency Packets ')
     legend('Optimized','Decided','TPC1','Location','NorthWest')
     xlabel('Node no.');
     ylabel('Delay of Emergency Packets(ms)');


      %���ܺ�

     figure(4)
     subplot(211)
     bar(result_Normal_Show_Energy)
     title('Normal-sum Energy Consume')
     legend('Optimized','Decided','TPC1','Location','NorthWest')
     xlabel('Node no.');
     ylabel('Total Energy Consume(��J)');
     subplot(212)
     bar(result_Emergency_Show_Energy)
     title('Emergency-sum Energy Consume')
     legend('Optimized','Decided','TPC1','Location','NorthWest')
     xlabel('Node no.');
     ylabel('Total Energy Consume(��J)');
end;