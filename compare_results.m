%compare results

fpath='E:\Karamanlis_20180405_252MEA20030_sr_le';
rstr=load(fullfile(fpath, 'rez.mat'));
rez=rstr.rez; clear rstr;
dataIgor=load(['C:\Users\Karamanlis_Dimokrati\Documents\DimosFolder\experiments\'...
    'Karamanlis_20180405_sr_le\data_analysis\1_fullfieldflicker\1_raw_data.mat']);

%%
maxTime=min([max(dataIgor.ftimes) 60*10]); %use only 10 minutes of recording
dt=0.1e-3; %in s
alltrains = blinkBinner( 0:dt:maxTime,dataIgor.spiketimes , 1, 1)'; 
maxLag=10*1e-3/dt;
%%
idcheck=48;
indsKilosort=rez.st3(rez.st3(:,2)==idcheck+1 & rez.st3(:,1)<size(alltrains,1),1);
trainKilosort=zeros(size(alltrains,1),1);
trainKilosort(indsKilosort)=1;
trainKilosort=gpuArray(trainKilosort);

allxcorr=zeros(2*maxLag+1,size(alltrains,2));
for cellId=1:size(alltrains,2)
    trainIgor=gpuArray(alltrains(:,cellId));
    trainxcorr=xcorr(trainKilosort,trainIgor, maxLag,'coeff');
    allxcorr(:,cellId)=gather(trainxcorr);
end
[~,bestMatch]=sort(max(allxcorr),'descend');
spkIgor=sum(alltrains(:,bestMatch(1)));
spkKilosort=numel(indsKilosort);

fprintf('Kilosort/Igor spikes : %d/%d (%0.02f), best %d \n',...
    spkKilosort,sum(spkIgor),spkKilosort/sum(spkIgor),bestMatch(1))
plot(allxcorr)


