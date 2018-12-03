%compare results

fpath='E:\Karamanlis_20180712_252MEA10030_mar_sr_le_pc2';
rstr=load(fullfile(fpath, 'rez.mat'));
st3=rstr.rez.st3; clear rstr;
dataIgor=load(['C:\Users\Karamanlis_Dimokrati\Documents\DimosFolder\experiments\'...
    'Karamanlis_20180712_mar_sr_le_pc2\data_analysis\7_frozencheckerflicker\7_raw_data.mat']);

%%
maxTime=min([max(dataIgor.ftimes) 60*10]); %use only 10 minutes of recording
dt=0.1e-3; %in s
alltrains = blinkBinner( 0:dt:maxTime,dataIgor.spiketimes , 1, 1)'; 
%%
maxLag=6*1e-3/dt;
idcheck=353;
indsKilosort=st3(st3(:,2)==idcheck+1 & st3(:,1)<size(alltrains,1),1);
trainKilosort=zeros(size(alltrains,1),1,'single');
trainKilosort(indsKilosort)=1;
trainKilosort=gpuArray(trainKilosort);

allxcorr=zeros(2*maxLag+1,size(alltrains,2));
for cellId=1:size(alltrains,2)
    trainIgor=gpuArray(single(alltrains(:,cellId)));
    trainxcorr=xcorr(trainKilosort,trainIgor, maxLag,'coeff');
    allxcorr(:,cellId)=gather(trainxcorr);
end
[~,bestMatch]=sort(max(allxcorr),'descend');
spkIgor=sum(alltrains(:,bestMatch(1)));
spkKilosort=numel(indsKilosort);

fprintf('Kilosort/Igor spikes : %d/%d (%0.02f), best %d \n',...
    spkKilosort,sum(spkIgor),spkKilosort/sum(spkIgor),bestMatch(1))
plot(allxcorr)


