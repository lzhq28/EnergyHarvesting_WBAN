%markov����
P_ini=[0.1,0.3,0.1,  0,0;
       0.7,0.2,0.3,0.1,0;
       0.2,0.4,0.3,0.3,0.1;
       0  ,0.1,0.2,0.4,0.4;
       0,0,0.1,0.2,0.5;];
P_state=[0.025;0.075;0.1;0.2;0.6];

for i=1:100
    P_tran=P_ini+(eye(size(P_ini,1))-P_ini)*P_state*pinv(P_state)
    P_tran(P_tran<0)=0;
    if(size(P_tran(P_tran<0),1)==0)
        break;
    end;
    P_ini=P_tran;
 
end;