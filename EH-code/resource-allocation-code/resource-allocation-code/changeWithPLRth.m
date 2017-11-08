%% 固定路径损耗，固定的速率情况下，研究随着丢包率门限能耗与丢包率和时延的关系
clc
clear all
format short
showCompareNormalResult=[];
showCompareEmergencyResult=[];
stepPNoise=1;%PNoise递减的步长
ver=13;%版本号
stepDeltaPL=2;%通过增加路径损耗来观察实验结果
deltaPLMaxIndex=41;
noiseMaxIndex=1;
avePLRSet=[1 0.95 0.9 0.85 0.8 0.75 0.7 0.65 0.6 0.55 0.5 0.45 0.4 0.35 0.3 0.25  0.2 0.15 0.1 0.05 ];
for deltaPLIndex=1:deltaPLMaxIndex
    for noiseIndex=1:1%noiseMaxIndex
        disp(['&&&&&&&&&&&&进度：',num2str(deltaPLIndex),['/'],num2str(deltaPLMaxIndex),['&&&&&&&&&&&&&&&&&']])
        PNoise=-94;%噪声  -106dB
        deltaPL=(deltaPLIndex-1)*stepDeltaPL;%增加的路径损耗值
        %% 计算参数
        channelPar(PNoise,deltaPL,miuTh,avePLRth)
        %% 本算法的计算
        performance(PNoise,deltaPL)
        %固定速率方法
        disp(['*************decide***************'])
        compareDecide(PNoise,deltaPL)
        %TPC方法
        disp(['*************TPC***************'])
        compareTPC(PNoise,deltaPL)
        [showCompareNormalResult, showCompareEmergencyResult]=showCompareResult(noiseIndex,deltaPLIndex,deltaPL,PNoise,showCompareNormalResult,showCompareEmergencyResult);

    end;
end;
