% comments
% neural net on segments : percentErrors =0.0023
% neural net on regions: 0.04

%% WHOLE THING NEURAL NET :)
disp ('training segments');
[Xsegs,Ysegs] =  getInfoScores (segDirMod,'segs');
[netSegments,~] = neuralNetTrain (Xsegs,Ysegs);
A = netSegments;

disp ('training regions');
[Xregs,Yregs] =  getInfoScores (segDirMod,'regs');
[netRegions,~] = neuralNetTrain (Xregs,Yregs);
E = netRegions;

%% to add new info and test training
segDirMod = '/Users/Stella/Documents/MATLAB/training100XnewReg/';
segDirMod = fixDir(segDirMod);
dontChangeScores = 1;
dirname = fixDir(segDirMod);
contents=dir([segDirMod,'*_seg*.mat']);
num_im = length(contents);
h = waitbar( 0, 'Recalculating region features' );

for i = 1 : num_im % go through all the images
    waitbar(i/num_im,h);
    dataname = [segDirMod,contents(i).name];
    data = load(dataname);

    % if there are no regions it makes regions from the segments
    %if ~isfield( data, 'regs' ); - i will just remake them for now!
    data = newRegionFeatures( data, [],dontChangeScores);
    % sets all scores to 1 for now..
    %end
    save(dataname,'-STRUCT','data');
end
close(h)




%% region training

% add bad regions
makeBadRegions2( segDirMod )
segData = dir([segDirMod,filesep,'*seg*.mat']);
FLAGS.im_flag = 2;

% for i = 1 : numel(segData)
%     data = load([segDirMod,filesep,segData(i).name]);
%     segData(i).name
%     
%     % update scores..
%     %[~,data.regs.scoreRaw] = calculateLassoScores (data.regs.info,E);
% 
%     [data,touch_list] = makeTrainingData (data,FLAGS)
%     if ~isempty(touch_list)
%         save([segDirMod,filesep,segData(i).name],'-STRUCT','data');
%     end
% end
% 
% 
% % 6) run regularized logistic regression on regions
% disp ('starting training on regions...');
% 
% [Xregs,Yregs] =  getInfoScores (segDirMod,'regs');
% % 0 for quadratic
% E = lassoLogisticRegression (Xregs,Yregs,0,0);
% [scores,rawScores] = calculateLassoScores (Xregs,E,0);
% 
% [indices] = find(~isnan(Yregs));
% Xregs = Xregs(indices,:);
% Yregs = Yregs(indices);
% 
% [indices] = find(isfinite(sum(Xregs,2)))
% Xregs = Xregs(indices,:);
% Yregs = Yregs(indices);


%% feature subset selection
% c = cvpartition(Yregs,'k',10);
% opts = statset('display','iter');
% fun = @(XT,yT,Xt,yt)...
%       (sum(yt==classify(Xt,XT,yT,'quadratic')));
% [fs,history] = sequentialfs(fun,Xregs,Yregs,'cv',c,'options',opts)
% 


