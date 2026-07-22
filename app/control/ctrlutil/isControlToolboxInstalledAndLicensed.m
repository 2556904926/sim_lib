function [ value, msg ] = isControlToolboxInstalledAndLicensed( ~ )
    value = isProductInstalledAndLicensed( 'Control System Toolbox' );
    msg = '';    
end