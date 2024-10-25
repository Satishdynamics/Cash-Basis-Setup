codeunit 50054 "SLGI Cash Basis Upgrade"
{
    Subtype = Upgrade;

    Permissions = tabledata "G/L Entry" = M;

    var

    trigger OnUpgradePerCompany()
    var
        GLE: Record "G/L Entry";
    begin
        // GLE.SetRange("G/L Account No.", '20600');
        // GLE.ModifyAll("SLGI CSH Tax Entry", true);
    end;

    trigger OnUpgradePerDatabase()
    begin
        // No upgrade code needed
    end;
}