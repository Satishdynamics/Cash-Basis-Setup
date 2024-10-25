report 50057 "SLGI CSH Export Cash Ledger"
{
    Caption = 'Cash Basis Export Ledger';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    trigger OnPreReport()
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgmt: Codeunit "File Management";
        OStream: OutStream;
    //SlgCrestSub: Codeunit "SLGI SUB Subscription";
    begin
        //SlgCrestSub.CheckProductEnabled('CSH');
        Clear(TempBlob);
        TempBlob.CreateOutStream(OStream);
        Xmlport.Export(Xmlport::"SLGI CSH Export Cash Ledger 2", OStream);
        FileMgmt.BLOBExport(TempBlob, FileName, true);
    end;

    var
        FileName: Label 'Cash Ledger Export.csv';
}