%% �̶�·����ģ��̶�����������£��о����Ŷ����������ܺ��붪���ʺ�ʱ�ӵĹ�ϵ
clc
clear all
format short
showCompareNormalResult=[];
showCompareEmergencyResult=[];
stepPNoise=1;%PNoise�ݼ��Ĳ���
ver=13;%�汾��
stepDeltaPL=2;%ͨ������·��������۲�ʵ����
deltaPLMaxIndex=41;
noiseMaxIndex=1;
avePLRSet=[1 0.95 0.9 0.85 0.8 0.75 0.7 0.65 0.6 0.55 0.5 0.45 0.4 0.35 0.3 0.25  0.2 0.15 0.1 0.05 ];
for deltaPLIndex=1:deltaPLMaxIndex
    for noiseIndex=1:1%noiseMaxIndex
        disp(['&&&&&&&&&&&&���ȣ�',num2str(deltaPLIndex),['/'],num2str(deltaPLMaxIndex),['&&&&&&&&&&&&&&&&&']])
        PNoise=-94;%����  -106dB
        deltaPL=(deltaPLIndex-1)*stepDeltaPL;%���ӵ�·�����ֵ
        %% �������
        channelPar(PNoise,deltaPL,miuTh,avePLRth)
        %% ���㷨�ļ���
        performance(PNoise,deltaPL)
        %�̶����ʷ���
        disp(['*************decide***************'])
        compareDecide(PNoise,deltaPL)
        %TPC����
        disp(['*************TPC***************'])
        compareTPC(PNoise,deltaPL)
        [showCompareNormalResult, showCompareEmergencyResult]=showCompareResult(noiseIndex,deltaPLIndex,deltaPL,PNoise,showCompareNormalResult,showCompareEmergencyResult);

    end;
end;
