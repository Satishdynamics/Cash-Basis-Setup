codeunit 50053 "SLGI Cash Basis Install"
{

    Subtype = Install;

    var
        CashBasisSetup: Record "SLGI Cash Basis Setup";
    //SlgCrestSub: Codeunit "SLGI SUB Subscription";

    trigger OnInstallAppPerCompany()
    begin
        //CashBasisSetup.CreateStandardSetup();
        //SlgCrestSub.CreateTrialLicense('CSH', 'Cash Basis Accounting', CalcDate('<30D>', Today()));
    end;

    trigger OnInstallAppPerDatabase()
    begin

    end;

}