%% ���㲻ͬ�ڵ��ڲ�ͬ�Ķ�����Լ���µ�miuTH,����������б��沢����ֵ,����ʱ�佫��Ƚϳ�
function [miuThNode,avePLRSet]=miuWithAvePLR()
%���������ļ�
% clc
% clear all
%% �ж�Ҫ�������Ƿ��Ѿ����ڣ��������ֱ�Ӽ��أ�������м���õ�
    format short %�����߾���
    configureChannelPar
    avePLRSet=[0.3 0.275 0.25 0.225 0.2 0.175 0.15 0.125 0.1 0.075 0.05 0.025 0.01 0.005];
    pathInfo='./data/miuThNode';
    for i=1:size(avePLRSet,2)
        if i==size(avePLRSet,2)
            pathInfo=strcat(pathInfo,num2str(avePLRSet(i)),'.mat');
        else
            pathInfo=strcat(pathInfo,num2str(avePLRSet(i)),'-');
        end
    end;
    if(exist(pathInfo,'file')==2) %
       load(pathInfo')
       disp(strcat(['����miuWithAvePLR��ʾ��','�����ļ����ڽ�ֱ�Ӽ��ػ�á�']))
       return
    end
%% �������� 
    Normal_P_Block=0;       %������
    Emergency_P_Block=0;       
    %BCH����
    n_BCH_PSDU=63;  %BCH�������
    k_BCH_PSDU=51;
    t_BCH_PSDU=2;
    %�ڵ�
    N_Node=5;%�ڵ���
    NoDis=[60,36,48,34,100];%�ڵ���Hub֮��ľ���
    No_n=[3.11,3.23,3.35,3.45,3.11];%�ڵ�·�����ϵ��
    N0P0=[35.2,41.2,32.2,32.5,35.2];%�ο�λ�ã�10cm������·�����ֵ
    NoPL=(N0P0+10.*No_n.*log10(NoDis./10))+deltaPL;%% ��ע�������������һ��������Ϊ�����������·��������۲�ʵ����
    d0=10; %�ο�����Ϊ10cm
    P_Sensitivity=-85; %����Ϊ�˼���򵥣�����������������Ϊ�����������޹صĹ̶�ֵ
    BandWidth=1000;%��λkbps
    DataRate=[121.4;242.8;485.6;971.2]; %��ѡ�����������
    R_basic=121.4;    %�ڵ���������
    %����С
    maxLenPacket=255;
    Normal_L_packet=ceil(Rate(1,:)*T_Frame);    %���ð��Ĵ�С
    index=find(Normal_L_packet>maxLenPacket*8);
        %����в���������������һ�������ܷ��͵����������������Щ���ݽ��о��ȷְ�
    if size(index,1)>0  
          Normal_L_packet(index)=ceil(Normal_L_packet(index)./ceil(Normal_L_packet(index)/(maxLenPacket*8))); %����T�ڲ��������ݱ����������о��ȷְ�
    end;
    numNormalPacket=ceil(ceil(Rate(1,:)*T_Frame)./Normal_L_packet);
    Emergency_L_packet=ceil(ceil(Rate(2,:)*T_Frame));    
    index=find(Emergency_L_packet>maxLenPacket*8);
         %����в���������������һ�������ܷ��͵����������������Щ���ݽ��о��ȷְ�
    if size(index,1)>0  
          Emergency_L_packet(index)=ceil(Emergency_L_packet(index)./ceil(Emergency_L_packet(index)/(maxLenPacket*8))); %����T�ڲ��������ݱ����������о��ȷְ�
    end;
    numEmergencyPacket=ceil(ceil(Rate(2,:)*T_Frame)./Emergency_L_packet);
%% ���ڲ�ͬ�������µ�����ȷ������ֵ
    Posture={'still','walk','run'};

    N_Posture=size(Posture,2);%���Ƶĸ���
    NodeKeseTmp{1}=[
        6.0475	4.8124	5.1064	2.6247	2.2669
        0.28	0.60	0.26	0.24	0.24    
    ];
    NodeKeseTmp{2}=[
        4.9483	7.2704	4.2025	3.0444	2.5985
        2.20	1.52	2.66	3.27	2.57
    ];
    NodeKeseTmp{3}=[
        5.7060	7.5404	3.8987	3.5210	1.9647
        2.19	2.00	2.37	1.98	1.80
    ];
    NodeKese(1,:)=sqrt(NodeKeseTmp{1}(1,:).^2+NodeKeseTmp{1}(2,:).^2);%��ͬ״̬�µ�����ȱ�׼��
    NodeKese(2,:)=sqrt(NodeKeseTmp{2}(1,:).^2+NodeKeseTmp{2}(2,:).^2);
    NodeKese(3,:)=sqrt(NodeKeseTmp{3}(1,:).^2+NodeKeseTmp{3}(2,:).^2);

    lenPacket=[Normal_L_packet;Emergency_L_packet];
%% miu��������
    miuMin=0;
    miuMax=30;
    delta=[0.001 0.0005];
    %% ���м���,˼�룬�ڸ�����ƽ����������������£�����ʹ�ö��ַ��������Ӧ������ֵ
    parFlag=1; %�Ƿ���ò��м���
    if(parFlag)
        tmpMiuThNode={};
        parfor i=1:N_Node
            tmpResult={};
            for pos =1:size(Posture,2)
                NP=N_Node*pos-N_Node+i
                disp(strcat(['(NP,i,pos):',num2str(NP),',',num2str(i),',',num2str(pos)]))
                kesi=NodeKese(pos,i);
                sliceResult=[]
                tic
                for h=1:size(avePLRSet,2)
                    for m=1:2
                        length = lenPacket(m,i);
                        sliceResult(m,h) = binarySearch(miuMin,miuMax,kesi,length,avePLRSet(h),delta(m));
                        %miuThNode{i,pos}(m,h)=binarySearch(miuMin,miuMax,kesi,length,avePLRSet(h),delta(m));
                    end
                end
                toc
                tmpResult{pos}=sliceResult;
            end
            tmpMiuThNode{i}=tmpResult;
        end
        % ��miuTh�������{nodeIndex,postureType}(normalORemergency,plrTH)������������
        for i=1:N_Node 
            for pos =1:size(Posture,2)
                miuThNode{i,pos}=tmpMiuThNode{i}{pos}
            end
        end
    else %�����ǲ��н��м���
        %�ɷ���õ���Ӧ�ľ�ֵ��ƽ��������֮��Ĺ�ϵ��
         for h=1:size(avePLRSet,2)
            for i=1:N_Node
                for pos=1:size(Posture,2)
                    kesi=NodeKese(pos,i);          
                    for m=1:2
                         length=lenPacket(m,i);
                         miuThNode{i,pos}(m,h)=binarySearch(miuMin,miuMax,kesi,length,avePLRSet(h),delta(m));                
                    end;
                end;
            end;
         end;
    end

%% ��������
    save(pathInfo,'miuThNode','avePLRSet','pathInfo')
 

