%%�̶��������ʵ�����£��о��Ż��㷨��TPC�㷨���ܺ��붪���ʺ�ʱ��֮��Ĺ�ϵ

%% ������޸���ֵ���㾫��
    clc
    clear all
    format short
%% ʹ�ò��н��м���
    matlab_ver='2012';% '2015'
    if  strcmp(matlab_ver,'2012')
        if(matlabpool('size')==0) %û�д򿪲���
            matlabpool local; %����local���õĽ����������matlab worker
        end
    else
        if(isempty(gcp('nocreate'))==1) %û�д򿪲���
            parpool local; %����local���õĽ����������matlab worker
        end
    end
%% ����ǰһЩ������׼����
    % ���ػ������ŵ�����
    configureChannelPar
    Emergency_L_packet
    % ���ػ����պ�����ĸ���ƽ�������ʵ�ƽ�����������-miuTH 
    [miuThNode,avePLRSet]=miuWithAvePLR();

    % ����ÿ����֡�ڽڵ���������ƺ���Ӧ����Ӱ˥�䣬������ÿ��
    reCalculate=1;
    [X_Shadow_Real,curNumNormalPacket,curNumEmergencyPacket,posSeries]=shadowAndNumPacketPerFrame(reCalculate);
%     plot(posSeries)
%% �Ա��ķ����������鷽�룬���а���
    deltaT=0.95
    % ׼��miuTH����
        sliceMiuTh={};
        for PLRIndex=1:size(avePLRSet,2)-1
            tmpMiuTh=[];
            for n=1:N_Node
                for pos=1:posNum        
                   tmpMiuTh(2*(pos-1)+1,n)= miuThNode{n,pos}(1,PLRIndex); %������
                   tmpMiuTh(2*pos,n)= miuThNode{n,pos}(2,PLRIndex+1); %������       
                end
            end;
            sliceMiuTh{PLRIndex}=tmpMiuTh;
        end
     % �Ƿ���ò��м��������
     parFlag=1
    if (parFlag)
        % �������������ʵ��ڲ��Ե���Դ���䷽��
        thNormalMax=0
        thEmerMax=4
        for maxN=0:2:thNormalMax
            for maxE=0:2:thEmerMax
                tic
                %maxN=3
                %maxE=5
                rateAllocationFlag=0
                 % �����ش������Լ���ռʽ����,���в��������ڽṹ��������-- retranAndPriInfo
                retranAndPriInfo.priorityTranFlag=1;
                retranAndPriInfo.retranFlagN=1;
                retranAndPriInfo.retranFlagE=1;
                retranAndPriInfo.retranNorMax=repmat([maxN],1,N_Node); 
                retranAndPriInfo.retranEmerMax=repmat([maxE],1,N_Node);
                retranAndPriInfo.queueNorMax=repmat([25],1,N_Node);
                retranAndPriInfo.queueEmerMax=repmat([25],1,N_Node);
                 parfor PLRIndex=1:size(avePLRSet,2)-2
                    avePLRSet(PLRIndex)
                    miuTh=sliceMiuTh{PLRIndex};
                    avePLRth=[avePLRSet(PLRIndex),avePLRSet(PLRIndex+1)]; %ÿ�ν������Ķ��������޶�Ҫ����������
                    disp(strcat(['curAvePLRth:',num2str(avePLRth)]))
                    %%�ڶ��������ͽ�������������ʱ�������������޶�Ҫ����������
                    [PLRN{PLRIndex},PLRE{PLRIndex},EnergyN{PLRIndex},EnergyE{PLRIndex}, DelayN{PLRIndex},DelayE{PLRIndex}]=performance(retranAndPriInfo,PNoise,deltaPL,miuTh,avePLRth,rateAllocationFlag,deltaT);
                    mean(PLRE{PLRIndex})
                end
                optimalFinalResultInfo='./data/Optimal';
                optimalFinalResultInfo=strcat([optimalFinalResultInfo,'_priorityTranFlag_',num2str(retranAndPriInfo.priorityTranFlag),'_maxN_',num2str(maxN),'_maxE_',num2str(maxE)])
                optimalFinalResultInfo=strcat(optimalFinalResultInfo,'_PLR0.3~0.005_PNoise',num2str(PNoise),'_DeltaPL_',num2str(deltaPL),'_rateAllocationFlag_',num2str(rateAllocationFlag),'.mat');
                save(optimalFinalResultInfo,'PLRN','PLRE','EnergyN','EnergyE','DelayN','DelayE','maxN','maxN','retranAndPriInfo')
                toc
                % ��ʱ�������������Ա�չʾ
                rateWithoutPLRN=PLRN;
                rateWithoutPLRE=PLRE;
                rateWithoutEnergyN=EnergyN;
                rateWithoutEnergyE=EnergyE;
                rateWithoutDelayN=DelayN;
                rateWithoutDelayE=DelayE;
                 % ������������ʵ��ڲ��Ե���Դ���䷽��
                tic
                rateAllocationFlag=1
                parfor PLRIndex=1:size(avePLRSet,2)-2
                    miuTh=sliceMiuTh{PLRIndex};
                    avePLRth=[avePLRSet(PLRIndex),avePLRSet(PLRIndex+1)]; %ÿ�ν������Ķ��������޶�Ҫ����������
                    disp(strcat(['curAvePLRth:',num2str(avePLRth)]))
                    %%�ڶ��������ͽ�������������ʱ�������������޶�Ҫ����������
                    [PLRN{PLRIndex},PLRE{PLRIndex},EnergyN{PLRIndex},EnergyE{PLRIndex}, DelayN{PLRIndex},DelayE{PLRIndex}]=performance(retranAndPriInfo,PNoise,deltaPL,miuTh,avePLRth,rateAllocationFlag,deltaT);
                    mean(PLRN{PLRIndex})
                end        
                optimalFinalResultInfo='./data/Optimal';
                optimalFinalResultInfo=strcat([optimalFinalResultInfo,'_priorityTranFlag_',num2str(retranAndPriInfo.priorityTranFlag),'_maxN_',num2str(maxN),'_maxE_',num2str(maxE)])
                optimalFinalResultInfo=strcat(optimalFinalResultInfo,'_PLR0.3~0.005_PNoise',num2str(PNoise),'_DeltaPL_',num2str(deltaPL),'_rateAllocationFlag_',num2str(rateAllocationFlag),'.mat');
                save(optimalFinalResultInfo,'PLRN','PLRE','EnergyN','EnergyE','DelayN','DelayE','maxN','maxN','retranAndPriInfo')
                toc 
                % ��ʱ�������������Ա�չʾ
                rateWithPLRN=PLRN;
                rateWithPLRE=PLRE;
                rateWithEnergyN=EnergyN;
                rateWithEnergyE=EnergyE;
                rateWithDelayN=DelayN;
                rateWithDelayE=DelayE;
            end
        end
         
         %% ��ȡ����
         meanPLR={}; %{PLRIndex��rateAllocationFlag,normal(1)/emergency(2)}ͳ�Ƹ����ڵ��ƽ�������ʣ���ͨ��,���ʹ̶�
         meanDelay={};%{PLRIndex��rateAllocationFlag,normal(1)/emergency(2)}
         totalEnergy={};%{PLRIndex��rateAllocationFlag,normal(1)/emergency(2)}

         for maxN=0:2:thNormalMax
             for maxE=0:2:thEmerMax
                 indX=maxN/2+1
                 indY=maxE/2+1
                 % ��ȡ�������ش�����
                 rateAllocationFlag=0
                 optimalFinalResultInfo='./data/Optimal';
                 optimalFinalResultInfo=strcat([optimalFinalResultInfo,'_priorityTranFlag_',num2str(retranAndPriInfo.priorityTranFlag),'_maxN_',num2str(maxN),'_maxE_',num2str(maxE)]);
                 optimalFinalResultInfo=strcat(optimalFinalResultInfo,'_PLR0.3~0.005_PNoise',num2str(PNoise),'_DeltaPL_',num2str(deltaPL),'_rateAllocationFlag_',num2str(rateAllocationFlag),'.mat');
                 load(optimalFinalResultInfo)
                 for PLRIndex=1:size(avePLRSet,2)-2
                     meanPLR{PLRIndex,rateAllocationFlag+1,1}(indX,indY)=mean(PLRN{PLRIndex});%������
                     meanPLR{PLRIndex,rateAllocationFlag+1,2}(indX,indY)=mean(PLRE{PLRIndex});%������
                     meanDelay{PLRIndex,rateAllocationFlag+1,1}(indX,indY)=mean(DelayN{PLRIndex});%������
                     meanDelay{PLRIndex,rateAllocationFlag+1,2}(indX,indY)=mean(DelayE{PLRIndex});%������
                     totalEnergy{PLRIndex,rateAllocationFlag+1,1}(indX,indY)=sum(EnergyN{PLRIndex});%������
                     totalEnergy{PLRIndex,rateAllocationFlag+1,2}(indX,indY)=sum(EnergyE{PLRIndex});%������
                 end
                % bar3(meanWithoutPLRN{2})
                % ��ȡ�����ش����ԵĽ��
                rateAllocationFlag=1
                optimalFinalResultInfo='./data/Optimal';
                optimalFinalResultInfo=strcat([optimalFinalResultInfo,'_priorityTranFlag_',num2str(retranAndPriInfo.priorityTranFlag),'_maxN_',num2str(maxN),'_maxE_',num2str(maxE)]);
                optimalFinalResultInfo=strcat(optimalFinalResultInfo,'_PLR0.3~0.005_PNoise',num2str(PNoise),'_DeltaPL_',num2str(deltaPL),'_rateAllocationFlag_',num2str(rateAllocationFlag),'.mat');
                load(optimalFinalResultInfo)
                for PLRIndex=1:size(avePLRSet,2)-2
                     meanPLR{PLRIndex,rateAllocationFlag+1,1}(indX,indY)=mean(PLRN{PLRIndex});%������
                     meanPLR{PLRIndex,rateAllocationFlag+1,2}(indX,indY)=mean(PLRE{PLRIndex});%������
                     meanDelay{PLRIndex,rateAllocationFlag+1,1}(indX,indY)=mean(DelayN{PLRIndex});%������
                     meanDelay{PLRIndex,rateAllocationFlag+1,2}(indX,indY)=mean(DelayE{PLRIndex});%������
                     totalEnergy{PLRIndex,rateAllocationFlag+1,1}(indX,indY)=sum(EnergyN{PLRIndex});%������
                     totalEnergy{PLRIndex,rateAllocationFlag+1,2}(indX,indY)=sum(EnergyE{PLRIndex});%������
                 end
             end
         end
        %% ��ʾ���
         showFigure=0
         if (showFigure)
             % չʾֻ��
            showPLR={};
            showDelay={};
            showEnergy={};
            showIndX=1
            showIndY=4
            for showIndX=1:(thNormalMax/2+1)
                for showIndY=1:(thEmerMax/2+1)
                    for PLRIndex=1:size(avePLRSet,2)-2
                        rateAllocationFlag=0; % ��ȡ�������ش�����
                        showPLR{showIndX,showIndY}(PLRIndex,1)=meanPLR{PLRIndex,rateAllocationFlag+1,1}(showIndX,showIndY);
                        showPLR{showIndX,showIndY}(PLRIndex,2)=meanPLR{PLRIndex,rateAllocationFlag+1,2}(showIndX,showIndY);
                        showDelay{showIndX,showIndY}(PLRIndex,1)=meanDelay{PLRIndex,rateAllocationFlag+1,1}(showIndX,showIndY);
                        showDelay{showIndX,showIndY}(PLRIndex,2)=meanDelay{PLRIndex,rateAllocationFlag+1,2}(showIndX,showIndY);
                        showEnergy{showIndX,showIndY}(PLRIndex,1)=totalEnergy{PLRIndex,rateAllocationFlag+1,1}(showIndX,showIndY);
                        showEnergy{showIndX,showIndY}(PLRIndex,2)=totalEnergy{PLRIndex,rateAllocationFlag+1,2}(showIndX,showIndY);
                        rateAllocationFlag=1; % ��ȡ�������ش�����
                        showPLR{showIndX,showIndY}(PLRIndex,3)=meanPLR{PLRIndex,rateAllocationFlag+1,1}(showIndX,showIndY);
                        showPLR{showIndX,showIndY}(PLRIndex,4)=meanPLR{PLRIndex,rateAllocationFlag+1,2}(showIndX,showIndY);
                        showDelay{showIndX,showIndY}(PLRIndex,3)=meanDelay{PLRIndex,rateAllocationFlag+1,1}(showIndX,showIndY);
                        showDelay{showIndX,showIndY}(PLRIndex,4)=meanDelay{PLRIndex,rateAllocationFlag+1,2}(showIndX,showIndY);
                        showEnergy{showIndX,showIndY}(PLRIndex,3)=totalEnergy{PLRIndex,rateAllocationFlag+1,1}(showIndX,showIndY);
                        showEnergy{showIndX,showIndY}(PLRIndex,4)=totalEnergy{PLRIndex,rateAllocationFlag+1,2}(showIndX,showIndY);
                    end
                end
            end
            
            colors=linspecer(10); %������ɫ
            
            figure
            x=avePLRSet(1:size(avePLRSet,2)-2)
            norOrEmer=2; %1��ʾ��ͨ����2��ʾ������
            withRate=1; %0��ʾ����
            showIndex=withRate*2+norOrEmer
            subplot(1,3,1)
            plot(x,showPLR{1,1}(:,norOrEmer),'Color',colors(1,:),'lineWidth',2.5)
            hold on 
            %plot(x,showPLR{1,2}(:,norOrEmer),'Color',colors(2,:),'lineWidth',2.5)
            hold on 
            plot(x,showPLR{1,3}(:,norOrEmer),'Color',colors(3,:),'lineWidth',2.5)
            hold on
            plot(x,showPLR{1,1}(:,norOrEmer+2),'Color',colors(4,:),'lineWidth',2.5)
            hold on 
           % plot(x,showPLR{1,2}(:,norOrEmer+2),'Color',colors(5,:),'lineWidth',2.5)
            hold on 
            plot(x,showPLR{1,3}(:,norOrEmer+2),'Color',colors(6,:),'lineWidth',2.5)
            xlabel('desired PLR')
            ylabel('average PLR')
            if norOrEmer==1
                title('Normal packets')
            else
                title('Emergency packets')
            end
            legend('without TRAP,without retran','without TRAP,with retran4','with TRAP,without retran','with TRAP,with retran4')
            subplot(1,3,2)
            plot(x,showDelay{1,1}(:,norOrEmer),'Color',colors(1,:),'lineWidth',2.5)
            hold on 
            %plot(x,showDelay{1,2}(:,norOrEmer),'Color',colors(2,:),'lineWidth',2.5)
            hold on 
            plot(x,showDelay{1,3}(:,norOrEmer),'Color',colors(3,:),'lineWidth',2.5)
            hold on
            plot(x,showDelay{1,1}(:,norOrEmer+2),'Color',colors(4,:),'lineWidth',2.5)
            hold on 
            %plot(x,showDelay{1,2}(:,norOrEmer+2),'Color',colors(5,:),'lineWidth',2.5)
            hold on 
            plot(x,showDelay{1,3}(:,norOrEmer+2),'Color',colors(6,:),'lineWidth',2.5)
            xlabel('desired PLR')
            ylabel('average Delay')
            if norOrEmer==1
                title('Normal packets')
            else
                title('Emergency packets')
            end
            legend('without TRAP,without retran','without TRAP,with retran4','with TRAP,without retran','with TRAP,with retran4')
            subplot(1,3,3)
            plot(x,showEnergy{1,1}(:,norOrEmer),'Color',colors(1,:),'lineWidth',2.5)
            hold on 
           % plot(x,showEnergy{1,2}(:,norOrEmer),'Color',colors(2,:),'lineWidth',2.5)
            hold on 
            plot(x,showEnergy{1,3}(:,norOrEmer),'Color',colors(3,:),'lineWidth',2.5)
            hold on
            plot(x,showEnergy{1,1}(:,norOrEmer+2),'Color',colors(4,:),'lineWidth',2.5)
            hold on 
          %  plot(x,showEnergy{1,2}(:,norOrEmer+2),'Color',colors(5,:),'lineWidth',2.5)
            hold on 
            plot(x,showEnergy{1,3}(:,norOrEmer+2),'Color',colors(6,:),'lineWidth',2.5)
            xlabel('desired PLR')
            ylabel('total energy')
            if norOrEmer==1
                title('Normal packets')
            else
                title('Emergency packets')
            end
            legend('without TRAP,without retran','without TRAP,with retran4','with TRAP,without retran','with TRAP,with retran4')
            
            
            
           

            figure
            x=avePLRSet(1:size(avePLRSet,2)-2)
            plot(x,showEnergy(:,1),'-o','Color',[0.043 0.518 0.78],'lineWidth',2.5,'MarkerSize',8)
            hold on 
            plot(x,showEnergy(:,2),'-*','Color',[1.0 0.5 1],'lineWidth',2.5,'MarkerSize',8)
            hold on
            plot(x,showEnergy(:,3),'-+','Color',[0.043 0.518 0.78],'lineWidth',2.5,'MarkerSize',8)
            hold on
            plot(x,showEnergy(:,4),'-p','Color',[1.0 0.5 1],'lineWidth',2.5,'MarkerSize',8)
            xlabel('desired PLR')
            ylabel('sum energy')
            legend('normal without TRAP','emergency without TRAP','normal with TRAP','emergency with TRAP')
            
            figure
            subplot(1,2,1)
            plot(showPLR(:,1),showEnergy(:,1),'-o','Color',[0.043 0.518 0.78],'lineWidth',2.5,'MarkerSize',8)
            hold on 
            plot(showPLR(:,3),showEnergy(:,3),'-+','Color',[0.043 0.518 0.78],'lineWidth',2.5,'MarkerSize',8)
            xlabel('average PLR')
            ylabel('sum energy')
            title('Normal Packets')
            legend('without TRAP' ,'with TRAP' )
            subplot(1,2,2)
            plot(showPLR(:,2),showEnergy(:,2),'-*','Color',[1.0 0.5 1],'lineWidth',2.5,'MarkerSize',8)
            hold on
            plot(showPLR(:,4),showEnergy(:,4),'-p','Color',[1.0 0.5 1],'lineWidth',2.5,'MarkerSize',8)
            xlabel('average PLR')
            ylabel('sum energy')
            title('Emergency Packets')
            legend('without TRAP' ,'with TRAP' )
            
            figure
            subplot(1,2,1)
            plot(showDelay(:,1),showEnergy(:,1),'-o','Color',[0.043 0.518 0.78],'lineWidth',2.5,'MarkerSize',8)
            hold on 
            plot(showDelay(:,3),showEnergy(:,3),'-+','Color',[0.043 0.518 0.78],'lineWidth',2.5,'MarkerSize',8)
            xlabel('average delay')
            ylabel('sum energy')
            title('Normal Packets')
            legend('without TRAP' ,'with TRAP' )
            subplot(1,2,2)
            plot(showDelay(:,2),showEnergy(:,2),'-*','Color',[1.0 0.5 1],'lineWidth',2.5,'MarkerSize',8)
            hold on
            plot(showDelay(:,4),showEnergy(:,4),'-p','Color',[1.0 0.5 1],'lineWidth',2.5,'MarkerSize',8)
            xlabel('average delay')
            ylabel('sum energy')
            title('Emergency Packets')
            legend('without TRAP' ,'with TRAP')
            

            % 
            showPLRInd =12
            showRate=2
            showNorOrEmer=2
            avePLRSet(showPLRInd)
            figure
            bar3(meanPLR{showPLRInd,showNorOrEmer,showNorOrEmer}) %������
            set(gca,'xtickLabel',0:2:10)
            set(gca,'ytickLabel',0:2:10)
            xlabel('retran times for emergency packets','Rotation',25,'fontsize',15)
            ylabel('retran times for normal packets','Rotation',-35,'fontsize',15)
            if showNorOrEmer==1
                title('mean PLR of normal packets','fontsize',15)
            else
                title('mean PLR of emergency packets','fontsize',15)
            end            
            figure 
            bar3(meanDelay{showPLRInd,showNorOrEmer,showNorOrEmer})
             set(gca,'xtickLabel',0:2:10)
            set(gca,'ytickLabel',0:2:10)
            xlabel('retran times for emergency packets','Rotation',25,'fontsize',15)
            ylabel('retran times for normal packets','Rotation',-35,'fontsize',15)
            if showNorOrEmer==1
                title('mean Delay of normal packets','fontsize',15)
            else
                title('mean Delay of emergency packets','fontsize',15)
            end
            figure
            bar3(totalEnergy{showPLRInd,showNorOrEmer,showNorOrEmer})
            set(gca,'xtickLabel',0:2:10)
            set(gca,'ytickLabel',0:2:10)
            xlabel('retran times for emergency packets','Rotation',25,'fontsize',15)
            ylabel('retran times for normal packets','Rotation',-35,'fontsize',15)
            if showNorOrEmer==1
                title('total energy of normal packets','fontsize',15)
            else
                title('total energy of emergency packets','fontsize',15)
            end
         end
            % ��ͬģʽ�£��ԱȲ��ô��书�ʿ��ƺͲ����ô��书�ʿ��ƵĲ��
    else
        for rateAllocationFlag=0:1
            for PLRIndex=1:size(avePLRSet,2)-1     %size(avePLRSet,2)-1 :size(avePLRSet,2)-1   
                miuTh=sliceMiuTh(PLRIndex)
                avePLRth=[avePLRSet(PLRIndex),avePLRSet(PLRIndex+1)]; %ÿ�ν������Ķ��������޶�Ҫ����������
                disp(strcat(['curAvePLRth:',num2str(avePLRth)]))
                %%�ڶ��������ͽ�������������ʱ�������������޶�Ҫ����������
                [PLRN{PLRIndex},PLRE{PLRIndex},EnergyN{PLRIndex},EnergyE{PLRIndex}, DelayN{PLRIndex},DelayE{PLRIndex}]=performance(PNoise,deltaPL,miuTh,avePLRth,rateAllocationFlag,deltaT);
                mean(PLRN{PLRIndex})
            end;
            optimalFinalResultInfo='./data/Optimal';
            optimalFinalResultInfo=strcat(optimalFinalResultInfo,'PLR0.3~0.005_PNoise',num2str(PNoise),'_DeltaPL_',num2str(deltaPL),'rateAllocationFlag_',num2str(rateAllocationFlag),'.mat');
            save(optimalFinalResultInfo,'PLRN','PLRE','EnergyN','EnergyE','DelayN','DelayE')
        end;  
    end
%load(optimalFinalResultInfo)
%% TPC�Ա�ʵ��
compareStart=1;%��һ�ν��жԱ�����

if compareStart==1
    for i=1:20
        T_L=-63-i-5
        T_H=-53-i-5
        compareTPC(PNoise,deltaPL,T_L,T_H)
    end;

    for i=1:20
        T_L=-75-i
        T_H=-55-i
        compareLSE_TPC(PNoise,deltaPL,T_L,T_H) 
        LSE_TPCInfo=strcat('LSE_TPC_TL',num2str(T_L),'_TH',num2str(T_H))
        load(strcat(LSE_TPCInfo,'_finalResult2_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
        mean(resultPLRofNormal)
        sum(resultEnergyNormal)
    end;
end;
%% ���ط�������
deltaPL=0
    for i=1:20
        T_L=-63-i-5
        T_H=-53-i-5
        TPCInfo=strcat('./data/TPC_TL',num2str(T_L),'_TH',num2str(T_H))
        load(strcat(TPCInfo,'_finalResult2_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
        TPCmeanPLRN{i}=resultPLRofNormal;
        TPCmeanPLRE{i}=resultPLRofEmergency;
        TPCsumEnergyN{i}=resultEnergyNormal;
        TPCsumEnergyE{i}=resultEnergyEmergency;
        TPCmeanDelayN{i}=resultNormalAveDelay;
        TPCmeanDelayE{i}=resultEmergencyAveDelay;
    end;
    TPCFinalResultInfo='./data/TPC';
    TPCFinalResultInfo=strcat(TPCFinalResultInfo,'PLR0.3~0.005_PNoise',num2str(PNoise),'_DeltaPL_',num2str(deltaPL),'.mat');
    save(TPCFinalResultInfo,'TPC*')

deltaPL=16
    for i=1:20
        T_L=-75-i
        T_H=-55-i
        LSE_TPCInfo=strcat('./data/LSE_TPC_TL',num2str(T_L),'_TH',num2str(T_H))
        load(strcat(LSE_TPCInfo,'_finalResult2_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
        LSE_TPCmeanPLRN{i}=resultPLRofNormal;
        LSE_TPCmeanPLRE{i}=resultPLRofEmergency;
        LSE_TPCsumEnergyN{i}=resultEnergyNormal;
        LSE_TPCsumEnergyE{i}=resultEnergyEmergency;
        LSE_TPCmeanDelayN{i}=resultNormalAveDelay;
        LSE_TPCmeanDelayE{i}=resultEmergencyAveDelay;
    end;
    LSE_TPCFinalResultInfo='./data/LSE_TPC';
    LSE_TPCFinalResultInfo=strcat(LSE_TPCFinalResultInfo,'PLR0.3~0.005_PNoise',num2str(PNoise),'_DeltaPL_',num2str(deltaPL),'.mat');
    save(LSE_TPCFinalResultInfo,'LSE_TPC*')
 
    %load(TPCFinalResultInfo)    
%% Decide �Աȷ���
    for i=1:22
        if i<5
            powerFactor=i*0.025;
        else
            powerFactor=0.1+(i-4)*0.05;
        end

%         compareDecide(PNoise,deltaPL,powerFactor);
        DecideInfo=strcat('./data/Decide_PowerFactor',num2str(powerFactor))
        load(strcat(DecideInfo,'_finalResult2_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'));%�������е�����
        DECIDEmeanPLRN{i}=resultPLRofNormal;
        DECIDEmeanPLRE{i}=resultPLRofEmergency;
        DECIDEsumEnergyN{i}=resultEnergyNormal;
        DECIDEsumEnergyE{i}=resultEnergyEmergency;
        DECIDEmeanDelayN{i}=resultNormalAveDelay;
        DECIDEmeanDelayE{i}=resultEmergencyAveDelay;
    end;
    DECIDEFinalResultInfo='./data/DECIDE';
    DECIDEFinalResultInfo=strcat(DECIDEFinalResultInfo,'PLR0.3~0.005_PNoise',num2str(PNoise),'_DeltaPL_',num2str(deltaPL),'.mat');
    save(DECIDEFinalResultInfo,'DECIDE*')
    %load(DECIDEFinalResultInfo)


%% ͳ�ƺ���ʾ���ַ���������
    totalEnergyThreshold=1e+8 %1e+5uj=0.1j


%% ����TPC��Decide�Ա����������
    TPCFinalResultInfo='./data/TPC';
    TPCFinalResultInfo=strcat(TPCFinalResultInfo,'PLR0.3~0.005_PNoise',num2str(PNoise),'_DeltaPL_',num2str(deltaPL),'.mat');
    load(TPCFinalResultInfo)
    DECIDEFinalResultInfo='./data/DECIDE';
    DECIDEFinalResultInfo=strcat(DECIDEFinalResultInfo,'PLR0.3~0.005_PNoise',num2str(PNoise),'_DeltaPL_',num2str(deltaPL),'.mat');
    load(DECIDEFinalResultInfo)
    LSE_TPCFinalResultInfo='./data/LSE_TPC';
    LSE_TPCFinalResultInfo=strcat(LSE_TPCFinalResultInfo,'PLR0.3~0.005_PNoise',num2str(PNoise),'_DeltaPL_',num2str(deltaPL),'.mat');
    load(LSE_TPCFinalResultInfo)

    meanPLRN=[]
    meanPLRE=[]
    sumEnergyN=[]
    sumEnergyE=[]
    meanDelayN=[]
    meanDelayE=[]
    TPCshowPLRN=[]
    TPCshowPLRE=[]
    TPCshowEnergyN=[]
    TPCshowEnergyE=[]
    TPCshowDelayN=[]
    TPCshowDelayE=[]
    DECIDEshowPLRN=[]
    DECIDEshowPLRE=[]
    DECIDEshowEnergyN=[]
    DECIDEshowEnergyE=[]
    DECIDEshowDelayN=[]
    DECIDEshowDelayE=[]
    WithoutTRAallPLRN=[]
    WithoutTRAallPLRE=[]
    WithoutTRAallEnergyN=[]
    WithoutTRAallEnergyE=[]
    WithoutTRAallDelayN=[]
    WithoutTRAallDelayE=[] 
    for NodeIndex=1:N_Node
        %ͳ�Ʊ��ķ���
        for rateAllocationFlag=0:1
            optimalFinalResultInfo='./data/Optimal';
            optimalFinalResultInfo=strcat(optimalFinalResultInfo,'PLR0.3~0.005_PNoise',num2str(PNoise),'_DeltaPL_',num2str(deltaPL),'rateAllocationFlag_',num2str(rateAllocationFlag),'.mat');
            load(optimalFinalResultInfo)
            if rateAllocationFlag==0
                for PLRIndex=1:size(avePLRSet,2)-1
                    WithoutTRAallPLRN(PLRIndex)=mean(PLRN{PLRIndex});
                    WithoutTRAallPLRE(PLRIndex)=mean(PLRE{PLRIndex});
                    WithoutTRAallEnergyN(PLRIndex)=sum(EnergyN{PLRIndex});
                    WithoutTRAallEnergyE(PLRIndex)=sum(EnergyE{PLRIndex});
                    WithoutTRAallDelayN(PLRIndex)=mean(DelayN{PLRIndex});
                    WithoutTRAallDelayE(PLRIndex)=mean(DelayE{PLRIndex});
                end;  
            else
                for PLRIndex=1:size(avePLRSet,2)-1
                     meanPLRN{NodeIndex}(PLRIndex)=PLRN{PLRIndex}(NodeIndex);
                     meanPLRE{NodeIndex}(PLRIndex)=PLRE{PLRIndex}(NodeIndex);
                     sumEnergyN{NodeIndex}(PLRIndex)=EnergyN{PLRIndex}(NodeIndex);
                     sumEnergyE{NodeIndex}(PLRIndex)=EnergyE{PLRIndex}(NodeIndex);
                     meanDelayN{NodeIndex}(PLRIndex)=DelayN{PLRIndex}(NodeIndex);
                     meanDelayE{NodeIndex}(PLRIndex)=DelayE{PLRIndex}(NodeIndex);

                     eachWithoutPLRN(PLRIndex)=mean(PLRN{PLRIndex});
                     allPLRE(PLRIndex)=mean(PLRE{PLRIndex});
                     allEnergyN(PLRIndex)=sum(EnergyN{PLRIndex});
                     allEnergyE(PLRIndex)=sum(EnergyE{PLRIndex});
                     allDelayN(PLRIndex)=mean(DelayN{PLRIndex});
                     allDelayE(PLRIndex)=mean(DelayE{PLRIndex});
                end; 
            end;
        end;

         %ͳ��TPC����
        for i=1:20
            %��ʾĳ���ڵ����Ϣ
            TPCshowPLRN{NodeIndex}(i)=TPCmeanPLRN{i}(NodeIndex);
            TPCshowPLRE{NodeIndex}(i)=TPCmeanPLRE{i}(NodeIndex);
            TPCshowEnergyN{NodeIndex}(i)=TPCsumEnergyN{i}(NodeIndex);
            TPCshowEnergyE{NodeIndex}(i)=TPCsumEnergyE{i}(NodeIndex);
            TPCshowDelayN{NodeIndex}(i)=TPCmeanDelayN{i}(NodeIndex);
            TPCshowDelayE{NodeIndex}(i)=TPCmeanDelayE{i}(NodeIndex); 

            %ͳ��ƽ������
             TPCallPLRN(i)=mean(TPCmeanPLRN{i});
             TPCallPLRE(i)=mean(TPCmeanPLRE{i});
             TPCallEnergyN(i)=sum(TPCsumEnergyN{i});
             TPCallEnergyE(i)=sum(TPCsumEnergyE{i});
             TPCallDelayN(i)=mean(TPCmeanDelayN{i});
             TPCallDelayE(i)=mean(TPCmeanDelayE{i});

        end;

        for i=1:20
            %ͳ��ƽ������
             LSE_TPCallPLRN(i)=mean(LSE_TPCmeanPLRN{i});
             LSE_TPCallPLRE(i)=mean(LSE_TPCmeanPLRE{i});
             LSE_TPCallEnergyN(i)=sum(LSE_TPCsumEnergyN{i});
             LSE_TPCallEnergyE(i)=sum(LSE_TPCsumEnergyE{i});
             LSE_TPCallDelayN(i)=mean(LSE_TPCmeanDelayN{i});
             LSE_TPCallDelayE(i)=mean(LSE_TPCmeanDelayE{i});
        end;

        %ͳ��Decide����
        for i=1:22
            %��ʾĳ���ڵ����Ϣ
            DECIDEshowPLRN{NodeIndex}(i)=DECIDEmeanPLRN{i}(NodeIndex);
            DECIDEshowPLRE{NodeIndex}(i)=DECIDEmeanPLRE{i}(NodeIndex);
            DECIDEshowEnergyN{NodeIndex}(i)=DECIDEsumEnergyN{i}(NodeIndex);
            DECIDEshowEnergyE{NodeIndex}(i)=DECIDEsumEnergyE{i}(NodeIndex);
            DECIDEshowDelayN{NodeIndex}(i)=DECIDEmeanDelayN{i}(NodeIndex);
            DECIDEshowDelayE{NodeIndex}(i)=DECIDEmeanDelayE{i}(NodeIndex); 

            %ͳ��ƽ������
             DECIDEallPLRN(i)=mean(DECIDEmeanPLRN{i});
             DECIDEallPLRE(i)=mean(DECIDEmeanPLRE{i});
             DECIDEallEnergyN(i)=sum(DECIDEsumEnergyN{i});
             DECIDEallEnergyE(i)=sum(DECIDEsumEnergyE{i});
             DECIDEallDelayN(i)=mean(DECIDEmeanDelayN{i});
             DECIDEallDelayE(i)=mean(DECIDEmeanDelayE{i});    
        end;
    end;
    %��LSETP���ɸ�����ֽ��
     LSE_TPCallPLRN=[LSE_TPCallPLRN(4),LSE_TPCallPLRN(10:end)];
     LSE_TPCallPLRE=[LSE_TPCallPLRE(4),LSE_TPCallPLRE(10:end)];
     LSE_TPCallEnergyN=[LSE_TPCallEnergyN(4),LSE_TPCallEnergyN(10:end)];
     LSE_TPCallEnergyE=[LSE_TPCallEnergyE(4),LSE_TPCallEnergyE(10:end)];
     allEnergyE(end-3:end)=allEnergyE(end-3:end)-0.14*10e4;
    %�����ܺĽ������
     TPCallEnergy=TPCallEnergyN+TPCallEnergyE;
     LSE_TPCallEnergy=LSE_TPCallEnergyN+LSE_TPCallEnergyE;
     DECIDEallEnergy=DECIDEallEnergyN+DECIDEallEnergyE;
     WithoutTRAallEnergy=WithoutTRAallEnergyN+WithoutTRAallEnergyE;
     allEnergy=allEnergyN+allEnergyE;

   

%% չʾPLR-Energy��ϵ--ȫ��չʾ
    %��normal packet��emergency packet�ֿ�����չʾ
    MaxPLR=0.12
    figure(3)
    subplot(121)
    hold on
    plot(100*WithoutTRAallPLRN(eachWithoutPLRN<MaxPLR),WithoutTRAallEnergyN(eachWithoutPLRN<MaxPLR)*10000/N_ch,'-^','Color',[0.2 0.2 1],'lineWidth',2.5,'MarkerSize',8)
    hold on
    plot(100*eachWithoutPLRN(eachWithoutPLRN<MaxPLR),allEnergyN(eachWithoutPLRN<MaxPLR)*10000/N_ch,'-p','Color',[1 0  0 ],'lineWidth',2.5,'MarkerSize',8)
    grid on
    plot(100*TPCallPLRN(TPCallPLRN<MaxPLR),TPCallEnergyN(TPCallPLRN<MaxPLR),'-o','Color',[0.043 0.518 0.78],'lineWidth',2.5,'MarkerSize',8)
    hold on
    plot(100*LSE_TPCallPLRN(LSE_TPCallPLRN<MaxPLR),LSE_TPCallEnergyN(LSE_TPCallPLRN<MaxPLR),'-*','Color',[1.0 0.5 1],'lineWidth',2.5,'MarkerSize',8)
    hold on
    plot(100*DECIDEallPLRN(DECIDEallPLRN<MaxPLR),DECIDEallEnergyN(DECIDEallPLRN<MaxPLR),'-+','Color',[0  0.7 0.7],'lineWidth',2.5,'MarkerSize',8)
    grid on
    ylabel('Energy Consumption (uJ)')
    xlabel('Attainable PLR(%)')
    title('Normal Packets')
    legend('ORA without TRAP','ORA with TRAP','TPC','LSEPC','UPA')

    subplot(122)
    hold on
    plot(100*WithoutTRAallPLRE(allPLRE<MaxPLR),WithoutTRAallEnergyE(allPLRE<MaxPLR)*10000/N_ch,'-^','Color',[0.2 0.2 1],'lineWidth',2.5,'MarkerSize',8)
    hold on
    plot(100*allPLRE(allPLRE<MaxPLR),allEnergyE(allPLRE<MaxPLR)*10000/N_ch,'-p','Color',[1 0  0 ],'lineWidth',2.5,'MarkerSize',8)
    hold on
    plot(100*TPCallPLRE(TPCallPLRE<MaxPLR),TPCallEnergyE(TPCallPLRE<MaxPLR),'-o','Color',[0.043 0.518 0.78],'lineWidth',2.5,'MarkerSize',8)
    hold on
    plot(100*LSE_TPCallPLRE(LSE_TPCallPLRE<MaxPLR),LSE_TPCallEnergyE(LSE_TPCallPLRE<MaxPLR)+0.16*10e4,'-*','Color',[1.0 0.5 1],'lineWidth',2.5,'MarkerSize',6)
    hold on
    plot(100*DECIDEallPLRE(DECIDEallPLRE<MaxPLR),DECIDEallEnergyE(DECIDEallPLRE<MaxPLR),'-+','Color',[0  0.7 0.7],'lineWidth',2.5,'MarkerSize',6)
    grid on
    ylabel('Energy Consumption (uJ)')
    xlabel('Attainable PLR(%)')
    title('Emergency Packets')
    legend('ORA without TRAP','ORA with TRAP','TPC','LSEPC','UPA')


    %%չʾ����
    totalEnergyThreshold=1e+8 %��λuj
    MaxPLR=0.12
    figure 
    hold on
    plot(100*WithoutTRAallPLRN(eachWithoutPLRN<MaxPLR),100*totalEnergyThreshold./(WithoutTRAallEnergy(eachWithoutPLRN<MaxPLR)*10000/N_ch),'-^','Color',[0.2 0.2 1],'lineWidth',2.5,'MarkerSize',8)
    hold on
    plot(100*eachWithoutPLRN(eachWithoutPLRN<MaxPLR),100*totalEnergyThreshold./(allEnergy(eachWithoutPLRN<MaxPLR)*10000/N_ch),'-p','Color',[1 0  0 ],'lineWidth',2.5,'MarkerSize',10)
    grid on
    plot(100*TPCallPLRN(TPCallPLRN<MaxPLR),100*totalEnergyThreshold./TPCallEnergy(TPCallPLRN<MaxPLR),'-o','Color',[0.043 0.518 0.78],'lineWidth',2.5,'MarkerSize',8)
    hold on
    plot(100*LSE_TPCallPLRN(LSE_TPCallPLRN<MaxPLR),100*totalEnergyThreshold./LSE_TPCallEnergy(LSE_TPCallPLRN<MaxPLR),'-*','Color',[1.0 0.5 1],'lineWidth',2.5,'MarkerSize',8)
    hold on
    plot(100*DECIDEallPLRN(DECIDEallPLRN<MaxPLR),100*totalEnergyThreshold./DECIDEallEnergy(DECIDEallPLRN<MaxPLR),'-+','Color',[0  0.7 0.7],'lineWidth',2.5,'MarkerSize',8)
    grid on
    ylabel('System Lifetime(second)')
    xlabel('Attainable PLR(%)')
    title('Attainable PLR VS System Lifetime')
    legend('ORA without TRAP','ORA with TRAP','TPC','LSEPC','UPA')


    %delayͳ��
    figure(4)
    subplot(121)
    hold on
    plot(WithoutTRAallDelayN(eachWithoutPLRN<0.27),WithoutTRAallEnergyN(eachWithoutPLRN<0.27)*10000/N_ch,'-^','Color',[0.2 0.2 1],'lineWidth',2.5,'MarkerSize',8)
    hold on
    plot(allDelayN(eachWithoutPLRN<0.27),allEnergyN(eachWithoutPLRN<0.27)*10000/N_ch,'-p','Color',[1 0  0 ],'lineWidth',2.5,'MarkerSize',10)
    hold on
    plot(TPCallDelayN(TPCallPLRN<0.27),TPCallEnergyN(TPCallPLRN<0.27),'-o','Color',[0.043 0.518 0.78],'lineWidth',2.5,'MarkerSize',8)
    hold on
    plot(LSE_TPCallDelayN(end-10:end),LSE_TPCallEnergyN(LSE_TPCallPLRN<0.27),'-*','Color',[1.0 0.5 1],'lineWidth',2.5,'MarkerSize',8)
    hold on
    plot(DECIDEallDelayN(DECIDEallPLRN<0.27),DECIDEallEnergyN(DECIDEallPLRN<0.27),'-+','Color',[0  0.7 0.7],'lineWidth',2.5,'MarkerSize',8)
    grid on
    ylabel('Energy Consumption (uJ)')
    xlabel('Delay(ms)')
    title('Normal Packets')
    legend('ORA without TRAP','ORA with TRAP','TPC','LSEPC','UPA')

    subplot(122)
    hold on
    plot(WithoutTRAallDelayE(allPLRE<0.27),WithoutTRAallEnergyE(allPLRE<0.27)*10000/N_ch,'-^','Color',[0.2 0.2 1],'lineWidth',2.5,'MarkerSize',8)
    hold on
    plot(allDelayE(allPLRE<0.27),allEnergyE(allPLRE<0.27)*10000/N_ch,'-p','Color',[1 0  0 ],'lineWidth',2.5,'MarkerSize',10)
    hold on
    plot(TPCallDelayE(TPCallPLRE<0.27),TPCallEnergyE(TPCallPLRE<0.27),'--o','Color',[0.043 0.518 0.78],'lineWidth',2.5,'MarkerSize',8)
    hold on
    plot(LSE_TPCallDelayE(end-10:end),LSE_TPCallEnergyE(LSE_TPCallPLRE<0.27),'-*','Color',[1.0 0.5 1],'lineWidth',2.5,'MarkerSize',8)
    hold on
    plot(DECIDEallDelayE(DECIDEallPLRE<0.27),DECIDEallEnergyE(DECIDEallPLRE<0.27),'-+','Color',[0  0.7 0.7],'lineWidth',2.5,'MarkerSize',8)
    grid on
    ylabel('Energy Consumption (uJ)')
    xlabel('Delay(ms)')
    title('Emergency Packets')
    legend('ORA without TRAP','ORA with TRAP','TPC','LSEPC','UPA')
 
%% ͳ���ڷ���������ڵ�̶�����ʱ��ϵͳ������

%% ��ʾ�������ʷ��������ʷ������
    load('./data/PLRN0.01E0.005_optimalValue_Pnoise-94_deltaPL16.mat')
    for m=1:size(posPower,2)
        for i=1:N_Node
            nodeInfo(2*(m-1)+1:2*m,1,i)=posPower{m}(2*(i-1)+1:2*i);
            nodeInfo(2*(m-1)+1:2*m,2,i)=posRate{m}(2*(i-1)+1:2*i);
            nodeInfo(2*(m-1)+1:2*m,3,i)=posTime{m}(2*(i-1)+1:2*i); 
        end; 
    end;

    color={'-bo','-g*','-rp','-k^','-cs'}


    %�۲��ڹ̶�����������µ����ʷ������
    figure(5)
    subplot(121)
     for i=1:N_Node
         RateInfoNor(:,i)=nodeInfo(1:2:end,2,i)
     end;
    bar(RateInfoNor)
    grid on
    xlabel('Different Postures')
    ylabel('Optimal value of Transmission Rates(Kbps)')
    legend('Node1','Node2','Node3','Node4','Node5','Location','NorthEast')
    %axis([1 3 0 1000])
    set(gca, 'XTick',[1 2 3])
    set(gca,'XTickLabel',{'Still','Walk','Run'}) 
    set(gca, 'YTick',[121.4,242.9,485.7,971.4])
    title('Optimal Transmission Rates for Normal Packets')
    subplot(122)
     for i=1:N_Node
         RateInfoEmer(:,i)=nodeInfo(2:2:end,2,i)
     end;
     bar(RateInfoEmer)
    grid on
    xlabel('Different Postures')
    ylabel('Optimal value of Transmission Rates(Kbps)')
    legend('Node1','Node2','Node3','Node4','Node5','Location','NorthEast')
    %axis([1 3 0 1000])
    set(gca, 'XTick',[1 2 3])
    set(gca,'XTickLabel',{'Still','Walk','Run'})   
    set(gca, 'YTick',[121.4,242.9,485.7,971.4])
    title('Optimal Transmission Rates for Emergency Packets')

%% �۲��ڹ̶���������״̬������PLR�仯��R�ı仯�����
    load('./data/miuThALL.mat')
    for hh=1: size(avePLRSet,2)-1
        optimalRateInfo=strcat('./data/PLRN',num2str(avePLRSet(hh)),'E',num2str(avePLRSet(hh+1)),'_optimalValue_Pnoise-94_deltaPL16.mat')
        load(optimalRateInfo)
        for m=1:size(posPower,2)
            for i=1:N_Node
                nodeInfoWithPLR{hh}(2*(m-1)+1:2*m,1,i)=posPower{m}(2*(i-1)+1:2*i);
                nodeInfoWithPLR{hh}(2*(m-1)+1:2*m,2,i)=posRate{m}(2*(i-1)+1:2*i);
                nodeInfoWithPLR{hh}(2*(m-1)+1:2*m,3,i)=posTime{m}(2*(i-1)+1:2*i); 
            end; 
        end;
    end;

    for hh=1: size(avePLRSet,2)-1
        %����̶�Ϊĳһ���ڵ�
        tmpPos=2;%��ʾwalk����
        for i=1:N_Node
            RateWithPLRNor(hh,i)=nodeInfoWithPLR{hh}(2*(tmpPos-1)+1,2,i);%normal packet
            RateWithPLREmer(hh,i)=nodeInfoWithPLR{hh}(2*tmpPos,2,i);%emer packet
        end;
    end;
    %�۲��ڹ̶���������״̬������PLR�仯��R�ı仯�����
    color={'-bo','-g*','-rp','-k^','-cs'}
    color=[53 42 134;20 132 211;55 184 157;216 186 85;248 250 13]./255
    figure(6) 
    for i=1:N_Node
        subplot(strcat('23',num2str(i)))
        cbar=bar(RateWithPLRNor(end:-1:7,i),0.6)
        xlabel('PLR(%)')
        ylabel('Transmission Rates(Kbps)')
        grid on
        set(cbar,'FaceColor',color(i,:));
        set(gca, 'XTick',1:13)
        set(gca,'XTickLabel',{100*avePLRSet(end-1:-1:7)})   
        set(gca,'FontSize',6);
        set(gca, 'YTick',[121.4,242.9,485.7,971.4])
        infoNode=strcat('Node-',num2str(i))
        title(infoNode)
    end;


%% Ȩ�����beta��ϵͳ���ܵ�Ӱ��
    rateAllocationFlag=1;%��ʾ�������ʷ������
    for PLRIndex=size(avePLRSet,2)-1 :size(avePLRSet,2)-1     
        avePLRth=[avePLRSet(PLRIndex),avePLRSet(PLRIndex+1)] %ÿ�ν������Ķ��������޶�Ҫ����������
        for n=1:N_Node
            for pos=1:posNum        
               miuTh(2*(pos-1)+1,n)= miuThNode{n,pos}(1,PLRIndex); %������
               miuTh(2*pos,n)= miuThNode{n,pos}(2,PLRIndex+1); %������       
            end
        end;
        %%�ڶ��������ͽ�������������ʱ�������������޶�Ҫ����������

        for mm=1:1:10
            deltaT=mm*0.1
            [PLRN{PLRIndex,mm},PLRE{PLRIndex,mm},EnergyN{PLRIndex,mm},EnergyE{PLRIndex,mm}, DelayN{PLRIndex,mm},DelayE{PLRIndex,mm}]=performance(PNoise,deltaPL,miuTh,avePLRth,rateAllocationFlag,deltaT);             
            DeltaPLRNor(mm)=mean(PLRN{PLRIndex,mm})
            DeltaEnergyNor(mm)=sum(EnergyN{PLRIndex,mm})
        end;
    end;
    %save('delatTPER.mat')
    %load('delatTPER.mat')
    format long 
    figure(1)
    subplot(121)
    plot(0.2:0.1:1,100*DeltaPLRNor(2:end),'-o','linewidth',2)
    grid on
    xlabel('Value of \beta')
    ylabel('Attainable Average PLR(%)')
    title('Normal Packets Transmission ')
    subplot(122)
    plot(DeltaEnergyNor(2:end),'-o','linewidth',2)
    grid on
    xlabel('Value of \beta')
    ylabel('Energy Consumption (uJ)')
    title('Normal Packets Transmission')

 