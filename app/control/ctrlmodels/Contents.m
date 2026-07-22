% Control System Toolbox -- Linear models.
%
% Model objects.
%   InputOutputModel - Overview of input/output model objects.
%   DynamicSystem    - Overview of dynamic system objects.
%   <a href="matlab:help InputOutputModel/get">get</a>, <a href="matlab:help InputOutputModel/set">set</a>         - Access and modify properties of model object.
%
% Numeric linear time-invariant (LTI) models.
%   numlti           - Overview of numeric LTI models.
%   tf               - Create or convert to transfer function model.
%   filt             - Create digital filter.
%   zpk              - Create or convert to zero/pole/gain model.
%   ss               - Create or convert to state-space model.
%   dss              - Create descriptor state-space model.
%   rss, drss        - Create random state-space models.
%   sparss           - Sparse descriptor state-space model.
%   mechss           - Sparse second-order model.
%   pid, pid2        - Create 1-DOF or 2-DOF PID in parallel form.
%   pidstd, pidstd2  - Create 1-DOF or 2-DOF PID in standard form.
%   frd              - Create or convert to frequency-response-data model.
%   ssdata,tfdata,zpkdata,... - Data extraction.
%
% Linear time-varying (LTV) and linear parameter-varying (LTV) models.
%   ltvss            - Create or convert to LTV state-space model.
%   lpvss            - Create or convert to LPV state-space model.
%   psample          - Sample LTV or LPV dynamics.
%   ssInterpolant    - Create LTV or LPV model from linearization data.
%   fixInput         - Fix value of some inputs and delete them.
%   
% State-space models.
%   prescale         - Optimal scaling of state-space model.
%   ss2ss            - State coordinate transformation.
%   ssequiv          - Equivalence transformation.
%   dss2ss           - Descriptor to explicit conversion.
%   balreal          - Balanced realization.
%   modalreal        - Modal realization.
%   compreal         - Companion realization.
%   xperm            - State reordering.
%   xsort            - State or DoF sorting in sparse models.
%   xelim            - State elimination.
%   augstate         - Augment output by appending states.
%   augoffset        - Map offset contribution to extra input.
%   ctrb, obsv       - Controllability and observability matrix.
%   gram             - Controllability and observability gramians.
%
% Frequency-response data (FRD) models.
%   <a href="matlab:help frd/fcat">fcat</a>             - Merge frequency responses.
%   <a href="matlab:help frd/fselect">fselect</a>          - Select frequency range or frequency points.
%   <a href="matlab:help frd/fnorm">fnorm</a>            - Gain at each frequency.
%   <a href="matlab:help frd/abs">abs</a>              - Magnitude of frequency response.
%   <a href="matlab:help frd/real">real</a>, <a href="matlab:help frd/imag">imag</a>       - Real and imaginary part of frequency response.
%   <a href="matlab:help frd/interp">interp</a>           - Interpolate frequency response data.
%   chgFreqUnit      - Change frequency vector units in FRD model.
%
% Generalized linear time-invariant (LTI) models.
%   genlti           - Overview of generalized LTI models.
%   AnalysisPoint    - Point of interest for analysis/tuning.
%   genmat           - Generalized matrix.
%   genss            - Generalized state-space model.
%   genfrd           - Generalized FRD model.
%   getValue         - Evaluate generalized model.
%   getBlockValue    - Get value of Control Design Block.
%   setBlockValue    - Modify value of Control Design Block.
%   showBlockValue   - Display Control Design Block values.
%   getPoints        - Get analysis point locations.
%   getLoopTransfer  - Compute open-loop transfer function.
%   getIOTransfer    - Compute closed-loop transfer function.
%   getSensitivity   - Compute sensitivity function.
%   getCompSensitivity - Compute complementary sensitivity function.
%   replaceBlock     - Replace block by value or by another block. 
%   sampleBlock      - Sample Control Design Blocks.
%   rsampleBlock     - Randomly sample Control Design Blocks.
%
% Time delays.
%   tf/exp           - Create pure continuous-time delays.
%   delayss          - Create state-space models with delayed terms.
%   setDelayModel    - Specify internal delay model (state space only).
%   getDelayModel    - Access internal delay model (state space only).
%   <a href="matlab:help InputOutputModel/hasdelay">hasdelay</a>         - True for models with time delays.
%   totaldelay       - Total delay between each input/output pair.
%   absorbDelay      - Replace delays by poles at z=0 or phase shift.
%   pade             - Pade approximation of continuous-time delays.
%   thiran           - Thiran approximation of fractional delays.
%
% Arrays of models.
%   stack            - Stack models along some array dimension.
%   <a href="matlab:help InputOutputModel/nmodels">nmodels</a>          - Number of models in model array.
%   <a href="matlab:help InputOutputModel/nmodels">reshape</a>          - Reshape model array.
%   <a href="matlab:help InputOutputModel/nmodels">permute</a>          - Permute model array dimensions.
%   voidModel        - Mark missing or irrelevant models in model array.
%
% Model algebra.
%   <a href="matlab:help InputOutputModel/plus">+</a>, <a href="matlab:help InputOutputModel/minus">-</a>             - Add and subtract models (parallel connection).
%   <a href="matlab:help InputOutputModel/mtimes">*</a>                - Multiply models (series connection).
%   <a href="matlab:help InputOutputModel/mldivide">\</a>                - Left divide -- sys1\sys2 means inv(sys1)*sys2.
%   <a href="matlab:help InputOutputModel/mrdivide">/</a>                - Right divide -- sys1/sys2 means sys1*inv(sys2).
%   <a href="matlab:help InputOutputModel/mpower">^</a>                - Powers of a model.
%   <a href="matlab:help InputOutputModel/transpose">.'</a>               - Transposition of input/output map.
%   <a href="matlab:help InputOutputModel/ctranspose">'</a>                - Pertranspose H(s) to H(-s).' or H(z) to H(1/z).'
%   <a href="matlab:help DynamicSystem/times">.*</a>               - Element-by-element multiplication.
%   <a href="matlab:help InputOutputModel/horzcat">[,]</a>, <a href="matlab:help InputOutputModel/vertcat">[;]</a>         - Concatenate models along inputs or outputs.
%   <a href="matlab:help InputOutputModel/inv">inv</a>              - Inverse of input/output model.
%   <a href="matlab:help InputOutputModel/conj">conj</a>             - Complex conjugation of model coefficients.
%
% Block diagram modeling.
%   append           - Aggregate models by appending inputs and outputs.
%   parallel         - Connect models in parallel.
%   series           - Connect models in series.
%   feedback         - Connect models with a feedback loop.
%   lft              - Generalized feedback interconnection.
%   connect          - Arbitrary block-diagram interconnection.
%   sumblk           - Specify summing junction (for use with CONNECT).
%
% Model transformation.
%   c2d              - Continuous to discrete conversion.
%   d2c              - Discrete to continuous conversion.
%   d2d              - Resample discrete-time model.
%   upsample         - Upsample discrete-time systems.
%   chgTimeUnit      - Change time units.
%   imp2exp          - Implicit to explicit conversion.

%   Copyright 1986-2023 The MathWorks, Inc.




