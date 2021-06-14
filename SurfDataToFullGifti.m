% Creates full gifti (mesh plus data) from data file sourceFile and mesh template giiTempl. 
% Essentially a wrapper around cat_io_FreeSurfer. Full gifti requires more storage space 
% than data only, but makes visualization easier.
%
% SurfDataToFullGifti(varargin)
% sourceFile    - freesurfer file (no file extension), OR
%               - gifti with a cdata field but no geometry (although the latter is optional; it's just the cdata that will be processed)
% targetFile 	- name of to be created file (optional)
% giiTempl      - mesh on which data from sourceFile should be mapped
%
% Version: 1.1
% Author: Björn Horing, bjoern.horing@gmail.com
% Date: 2021-06-14
%
% Version notes
% 1.1
% - function description, comments for Git; removed localized defaults

function SurfDataToFullGifti(varargin)
    
    if ~nargin % then we use demo files, if we have them
        cP = fileparts(mfilename('fullpath'));
        sourceFile = [cP filesep 'demoFS'];
        [p,f,e] = fileparts(sourceFile);
        targetFile = [p filesep f e '.gii']; % e just to be sure there isn't a stray dot somewhere
        giiTempl = gifti([cP filesep 'demoMesh.gii']); % use demo mesh
    elseif nargin==1 % then target file will be named like source file, but with gii    
        sourceFile = varargin{1};
        [p,f,e] = fileparts(sourceFile);
        targetFile = [p filesep f e '.gii']; % e just to be sure there isn't a stray dot somewhere
        giiTempl = gifti; % no source mesh available
    elseif nargin==2
        sourceFile = varargin{1};
        targetFile = varargin{2};        
        giiTempl = gifti; % no source mesh available
    elseif nargin==3
        sourceFile = varargin{1};
        targetFile = varargin{2};
        if isempty(targetFile)
            targetFile = [sourceFile '.gii'];
        end
        giiTempl = gifti(varargin{3});
    else
        error('Incorrect number of arguments.');
    end 
 
    if strcmp(sourceFile,targetFile)
        error('Source file and target file are identical. If you know what you''re doing, comment me out and proceed.');
    end
    
    pt = fileparts(targetFile);
    if isempty(pt) % then we use the source file's path
        [ps,~,~] = fileparts(sourceFile);           
        targetFile = [ps filesep targetFile];
    end    
    
    if isempty(regexp(sourceFile,'\.gii$','ONCE')) % we really have no way of knowing what extension to expect, so we only consider gifti as alternative...
        sourceData = cat_io_FreeSurfer('read_surf_data',sourceFile);
    else
        sourceData = gifti(sourceFile);
        sourceData = sourceData.cdata;
    end
    giiTempl.cdata = [];
    giiTempl.cdata = sourceData;
    
    fprintf('Saving full gifti at %s... ',targetFile);
    save(giiTempl,targetFile); % nb THIS IS SPM's @gifti's save.m, not the MATLAB general function
    fprintf('done.\n');
    