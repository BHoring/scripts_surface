% Erode surface patch (cdata) projected on surface mesh, for example one whose gaps were closes using GiftiDilate.
% Intended for application on SPM surfaces (e.g. as obtained via CAT12).
%
% Download demoMesh.gii and demoPatch.gii for demo purposes.
%
% Also see companion function GiftiDilate.m.
%
% GiftiDilate(meshPath,patchPath,outPath[,NIt])
% meshPath      - path to full surface mesh gifti (e.g. brain surface)
% patchPath     - path to surface patch as defined in cdata (binary, valid==1); n of vertices must correspond to meshPath
% outPath       - designated location for dilated gifti file
% NIt           - number of iterations (~expansion steps)
% saveFullMesh  - save mesh and patch data, or mesh data only
%
% Version: 1.1
% Author: Björn Horing, bjoern.horing@gmail.com
% Date: 2021-04-16
%
% Version notes
% 1.1
% - function description, comments for Git; removed localized defaults

function GiftiErode(varargin)

    if ~nargin % use demo settings, requires 
        cP              = fileparts(mfilename('fullpath'));
        meshPath        = [cP filesep 'demoMesh.gii'];
        patchPath       = [cP filesep 'demoPatch.gii']; % expects binary data for now, with valid entry==1
        outPath         = [cP filesep 'demoPatchEroded.gii'];
        NIt             = 2; % number of dilations, recommended 2+ to close intra-patch gaps
        saveFullMesh    = 1;
        
        if ~exist(meshPath,'file') || ~exist(patchPath,'file')
            error('Demo files not found.');
        end
    elseif nargin>2
        meshPath        = varargin{1};
        patchPath       = varargin{2};
        outPath         = varargin{3};
        NIt             = 2; % number of dilations, recommended 2+ to close intra-patch gaps
        saveFullMesh    = 1;
    else
        error('Insufficient number of input arguments (%d), or demo files not found.',nargin);
    end

    meshg = gifti(meshPath); % mesh to determine adjacencies/neighbors
    patchg = gifti(patchPath); % patch(es) to be eroded
    cdata = patchg.cdata; % this will be boiled down below, roughly by NIt vertices

    meshNeighbors=spm_mesh_neighbours(meshg);

    for it = 1:NIt % for a number of iterations (~number of adjacent vertices)...
        patchExtent = find(cdata==1);        
        currentNeighbors=meshNeighbors(patchExtent,:);
        patchExtent(end+1) = 0; % to account for zeros
        toRemove = ~all(ismember(currentNeighbors,patchExtent),2);
        patchExtent(end) = []; % ahem
        cdata(patchExtent(toRemove)) = NaN; % remove all from patch that are not fully encircled
    end
    fprintf('Patch vertices reduced from %d to %d (%d iterations).\n',sum(patchg.cdata==1),sum(cdata==1),NIt);   
    
    if saveFullMesh % save mesh and patch data
        meshg.cdata = cdata;
        newg = gifti(meshg);
    else % save only patch data
        newg = gifti(cdata);
    end    
    
    fprintf('Saving eroded patch at %s... ',outPath);
    save(newg,outPath) % nb THIS IS SPM's @gifti's save.m, not the MATLAB general function
    fprintf('done.\n')    
    