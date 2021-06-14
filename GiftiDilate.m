% Close gaps in surface patch (cdata) projected on surface mesh.
% Intended for application on SPM surfaces (e.g. as obtained via CAT12).
%
% Download demoMesh.gii and demoPatch.gii for demo purposes.
%
% Also see companion function GiftiErode.m.
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

function GiftiDilate(varargin)

    if ~nargin % use demo settings, requires 
        cP              = fileparts(mfilename('fullpath'));
        meshPath        = [cP filesep 'demoMesh.gii'];
        patchPath       = [cP filesep 'demoPatch.gii']; % expects binary data for now, with valid entry==1
        outPath         = [cP filesep 'demoPatchDilated.gii'];
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
        error('Insufficient number of input arguments (%d).',nargin);
    end
    
    % overrides
    if nargin>3; NIt = varargin{4}; end
    if nargin>4; saveFullMesh = varargin{5}; end

    outDir = fileparts(outPath);
    if ~exist(outDir,'dir') && ~isempty(outDir)
        mkdir(outDir);
    end
    
    meshg = gifti(meshPath); % mesh to determine adjacencies/neighbors
    patchg = gifti(patchPath); % patch(es) to be expanded
    cdata = patchg.cdata; % this will be expanded below, roughly by NIt vertices
    meshNeighbors = spm_mesh_neighbours(meshg);
    
    for it = 1:NIt % for a number of iterations (~number of adjacent vertices)...
        patchExtent = find(cdata==1);
        currentNeighbors = meshNeighbors(patchExtent,:);
        currentNeighbors = unique(currentNeighbors(currentNeighbors>0));
        cdata(currentNeighbors) = 1; % ... extend the patch
    end
    fprintf('Patch vertices increased from %d to %d (%d iterations).\n',sum(patchg.cdata==1),sum(cdata==1),NIt);   
    
    if saveFullMesh % save mesh and patch data
        meshg.cdata = cdata;
        newg = gifti(meshg);
    else % save only patch data
        newg = gifti(cdata);
    end
    
    fprintf('Saving dilated patch at %s... ',outPath);
    save(newg,outPath) % nb THIS IS SPM's @gifti's save.m, not the MATLAB general function
    fprintf('done.\n')
