%% Branch 1. basic config - PEDRO
AddPaths('');
parpool(16) % initialize number of cores

%% Initialize Directories
project_name = 'MMR';

%% Retrieve subject information
sbj_name ='S21_166_TM';
center = 'Stanford';
%% Get block names
block_names = BlockBySubj(sbj_name,project_name)
server_root = '/Volumes/neurology_jparvizi$/';
comp_root = '/Volumes/LBCN8T/Stanford/data';
code_root = '/Users/pinheirochagas/Pedro/Stanford/code/lbcn_preproc/';
dirs = InitializeDirs(project_name, sbj_name); % 'Pedro_NeuroSpin2T'


%% Get iEEG and Pdio sampling rate and data format
[fs_iEEG, fs_Pdio, data_format] = GetFSdataFormat(sbj_name, center);

%% Create subject folders
CreateFolders(sbj_name, project_name, block_names, center, dirs, data_format, 'auto')


%% Copy the iEEG and behavioral files from server to local folders
for i = 1:length(block_names)
    CopyFilesServer(sbj_name,project_name,block_names{i},data_format,dirs)
end


%% Branch 2 - data conversion - PEDRO
ref_chan = [];
epi_chan = [];
empty_chan = [];

if strcmp(data_format, 'edf')
    SaveDataNihonKohden(sbj_name, project_name, block_names, dirs, ref_chan, epi_chan, empty_chan) %
elseif strcmp(data_format, 'TDT')
    SaveDataDecimate(sbj_name, project_name, block_names, fs_iEEG, fs_Pdio, dirs, ref_chan, epi_chan, empty_chan) %% DZa 3051.76
else
    error('Data format has to be either edf or TDT format')
end

%% Convert berhavioral data to trialinfo
OrganizeTrialInfoMMR_rest(sbj_name, project_name, block_names, dirs) 

%% Branch 3 - event identifier
EventIdentifier(sbj_name, project_name, block_names, dirs,2) % new ones, photo = 1; old ones, photo = 2; china, photo = varies, depends on the clinician, normally 9, mic = 2


%% Branch 4 - bad channel rejection
% [refChan, badChan, epiChan, emptyChan] = GetMarkedChans(sbj_name);
load(sprintf('%s/originalData/%s/global_%s_%s_%s.mat',dirs.data_root,sbj_name,project_name,sbj_name,block_names{1}));
ref_chan = [];
epi_chan = [];
empty_chan = []; % INCLUDE THAT in SaveDataNihonKohden SaveDataDecimate

BadChanRejectCAR(sbj_name, project_name, block_names, dirs)

%% Branch 5 - Time-frequency analyses
% Load elecs info
load(sprintf('%s/originalData/%s/global_%s_%s_%s.mat',dirs.data_root,sbj_name,project_name,sbj_name,block_names{1}),'globalVar');
elecs = setdiff(1:globalVar.nchan,globalVar.refChan);


for i = 1:length(block_names)
    parfor ei = 1:length(elecs)
         WaveletFilterAll(sbj_name, project_name, block_names{i}, dirs, elecs(ei), 'HFB', [], [], [], 'Band') % only for HFB
%         WaveletFilterAll(sbj_name, project_name, block_names{i}, dirs, elecs(ei), 'Spec', [], [], true, 'Spec') % across frequencies of interest
    end
end

%% Branch 6 - Epoching, identification of bad epochs and baseline correction
epoch_params = genEpochParams(project_name, 'stim');
epoch_params.noise.method = 'trials';
for i = 1:length(block_names)
    bn = block_names{i};
    parfor ei = 1:length(elecs)
                  EpochDataAll(sbj_name, project_name, bn, dirs,elecs(ei), 'HFB', [],[], epoch_params,'Band')
         %EpochDataAll(sbj_name, project_name, bn, dirs,elecs(ei), 'CAR', [],[], epoch_params,'CAR')
        %                    EpochDataAll(sbj_name, project_name, bn, dirs,elecs(ei), 'SpecDense', [],[], epoch_params,'Spec')
    end
end

epoch_params = genEpochParams(project_name, 'resp');
for i = 1:length(block_names)
    bn = block_names{i};
    parfor ei = 1:length(elecs)
         EpochDataAll(sbj_name, project_name, bn, dirs,elecs(ei), 'HFB', [],[], epoch_params,'Band')
%          EpochDataAll(sbj_name, project_name, bn, dirs, elecs(ei), 'SpecDense', [],[], epoch_params,'Spec')
    end
end


%% DONE PREPROCESSING.


%% Branch 7 - Plotting
plot_params = genPlotParams(project_name,'timecourse');
plot_params.noise_method = 'trials'; %'trials','timepts','none'
plot_params.noise_fields_trials = {'bad_epochs_HFO','bad_epochs_raw_HFspike'};
plot_params.noise_method = 'trials'; %'trials','timepts','none'
plot_params.noise_fields_trials = {'bad_epochs_HFO','bad_epochs_raw_HFspike'};
PlotTrialAvgAll(sbj_name,project_name,block_names,dirs,[],'HFB','stim','condNames', [], plot_params,'Band') % condNames
plot_params.xlim = [-0.850 0.2];
PlotTrialAvgAll(sbj_name,project_name,block_names,dirs,[],'HFB','resp','condNames', [], plot_params,'Band') % condNames


%% ANALYSES

%% 1. Selectivity math vs. memory

%% 2. ROL temporal dynamics

%% 3. Connectivity - lagged correlation, PAC and PLV

%% 4. Brain behavioral interaction 


