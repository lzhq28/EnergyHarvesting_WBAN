%% ʹ��yalmip����ggp���
%% ���ز���
GGPpar
channelPar
load('QoS.mat')
%��������������
N_ch=10; %��֡�ĸ���
N_Node=5;   %����ڵ�ĸ���
% min_X_Shadow=0;
% step_X_Shadow=0.5;
% max_X_Shadow=min_X_Shadow+(N_ch-1)*step_X_Shadow;
 

 ProbPosture=[0.5,0.3,0.2];
 pos=1;%��ʾ��ǰ����������״̬
 %�������
 for m=1:N_ch
     if m<= ProbPosture(1)*N_ch
         pos=1;
     elseif m<=(ProbPosture(1)+ProbPosture(2))*N_ch
         pos=2;
     else 
         pos=3;
     end;
  
    %ÿһ֡�ڵ���Ӱ˥�䲻�䣬��ͬ֡����Ӱ˥��Ϊ���ֵ
     X_Shadow_Real=(NodeKese(pos,:)'.*randn(N_Node,1));
     % ���ñ���
     P=sdpvar(N_Node*2,1);
     R=sdpvar(N_Node*2,1);
     t=sdpvar(N_Node*2,1);
     tmpV=sdpvar(N_Node*2,1);
     sum_t=sdpvar(1);
     %����Ŀ�꺯��--����ʽ
     obj=0; %����һ���ն���ʽ
     constr=[]; %����һ���վ���
     status_Node_of_eachFrame=[];%�����洢ÿ�����Ĳ����ʹ����Լ�
     NodeSet=[1,2,3,4,5];%��Ҫ������ȷ����Щ�ڵ����Ϊ��Ӱ˥��ϴ�������жϲ���������
     for i=1:N_Node 
         if ~isempty(find(NodeSet==i))
             Normal_index=(i-1)*2+1;
             Emergency_index=(i-1)*2+2;
             %�ۼӷ����ʱ��
             sum_t=sum_t+t(Normal_index)+t(Emergency_index);
            %����Ŀ�꺯��        
            obj=obj+((a+1)*P(Normal_index)+b)*t(Normal_index)+((a+1)*P(Emergency_index)+b)*t(Emergency_index);
            %% ����Լ��            
                %��Ӱ˥��
                constr=[constr;QoS_PiR(2*(pos-1)+1,i)<=P(Normal_index)*R(Normal_index)^(-1) ;QoS_PiR(2*(pos-1)+2,i)<=P(Emergency_index)*R(Emergency_index)^(-1)];
                %ʱ��
                constr=[constr;QoS_Rt(1,i)<=R(Normal_index)*t(Normal_index);QoS_Rt(2,i)<=R(Emergency_index)*t(Emergency_index)];
                constr=[constr;QoS_iR(1,i)*R(Normal_index)^(-1)+tmpV(Normal_index)<=QoS_D(1,i)];
                constr=[constr;QoS_N_RtiTmpV(1,i)*R(Normal_index)*t(Normal_index)*tmpV(Normal_index)^(-1)+QoS_N_Con(1,i)<=QoS_N_Rt(1,i)*R(Normal_index)*t(Normal_index)];
                constr=[constr;QoS_iR(2,i)*R(Emergency_index)^(-1)+tmpV(Emergency_index)<=QoS_D(2,i)];
                constr=[constr;QoS_E_iRtTmpV(1,i)*R(Emergency_index)^(-1)*t(Emergency_index)^(-1)*tmpV(Emergency_index)^(-1)+QoS_E_iTmpV(1,i)*tmpV(Emergency_index)^(-1)+QoS_E_Con(1,i)<=QoS_E_Rt(1,i)*R(Emergency_index)*t(Emergency_index)]; 

    %             %����Լ��
                constr=[constr;DataRate(1)<=R(Normal_index);DataRate(1)<=R(Emergency_index)];
                constr=[constr;R(Normal_index)<=DataRate(4);R(Emergency_index)<=DataRate(4)];
                %���书��Լ��
                constr=[constr;P_tx_min<=P(Normal_index);P_tx_min<=P(Emergency_index)];
                constr=[constr;P(Normal_index)<=P_tx_max;P(Emergency_index)<=P_tx_max];
        end; 
     end;

      %��ʱ��Լ��
      constr=[constr;sum_t<=T_Frame];  
      disp(['-----------��',num2str(m),'���Ż���ʼ-----------'])
      X_Shadow_Real
         %����ͳ�Ƽ����ʱ
     tic
      %% ��Ҫ����.....���������
      solution = solvesdp( constr,obj);
      disp(['-----------��',num2str(m),'���Ż�����-----------'])

      %% ͳ�ƽ��
      Result_Power{m}= double(P)
      Result_Rate{m}=double(R)      
      Result_time{m}=double(t)
%       double(R)
%       double(t)
      Result_tmpV_real{m}=double(tmpV);
      Result_minSumEnergy(m)=double(obj);
      %���㵥�μ����ʱ
      final_calTime(m)=toc;   %ͳ��ÿ�μ���ʱ��
      toc
      final_X_Shadow{m}=X_Shadow_Real; %ͳ��ÿ֡�ڵĸ����ڵ����Ӱ˥��     
      
 end;

 
 