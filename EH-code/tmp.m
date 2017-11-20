%% 测试YALMIP
% blues = randn(2,25);
% greens = randn(2,25)+2;
% a = sdpvar(2,1);
% b = sdpvar(1);
% u = sdpvar(1,25);
% v = sdpvar(1,25);
% Constraints = [a'*greens+b >= 1-u, a'*blues+b <= -(1-v), u >= 0, v >= 0]
% Objective = sum(u)+sum(v)
% Constraints = [Constraints, -1 <= a <= 1];
% Ops = sdpsettings('verbose',0,'solver','mosek');
% results=optimize(Constraints,Objective,Ops)
% x = sdpvar(2,1);
% P1 = [-5<=x<=5, value(a)'*x+value(b)>=0];
% P2 = [-5<=x<=5, value(a)'*x+value(b)<=0];
% clf
%% 测试并行计算

parfor deltaPL =1:10
    QoS = deltaPL;
    pathInfo = strcat(['QoS_deltaPL-',num2str(deltaPL),'.mat']);
    parsave(pathInfo, QoS)
end

%% 观察目标函数
N_max = 100;
x=0:1:2*N_max
y=(power(N_max,2)-power((N_max-x),2))/power(N_max,2)
figure
plot(x,y)
hold on
plot([N_max,N_max],[0,1])
text(N_max,0.5,' \leftarrow B_{i}');
xlabel('Transmission bits with allocated slots')
ylabel('Equivalent performance')
