query 50050 "SLGI CSH Analysis View Source"
{
    Caption = 'Cash Analysis View Source';

    elements
    {
        dataitem(Analysis_View; "Analysis View")
        {
            filter(AnalysisViewCode; "Code")
            {
            }
            dataitem(SlgC_Cash_G_L_Entry; "SLGI Cash G/L Entry")
            {
                SqlJoinType = CrossJoin;
                filter(EntryNo; "Entry No.")
                {
                }
                column(GLAccNo; "G/L Account No.")
                {
                }
                column(PostingDate; "Posting Date")
                {
                }
                column(DimensionSetID; "Dimension Set ID")
                {
                }
                column(Amount; Amount)
                {
                    Method = Sum;
                }
                column(DebitAmount; "Debit Amount")
                {
                    Method = Sum;
                }
                column(CreditAmount; "Credit Amount")
                {
                    Method = Sum;
                }
                dataitem(DimSet1; "Dimension Set Entry")
                {
                    DataItemLink = "Dimension Set ID" = SlgC_Cash_G_L_Entry."Dimension Set ID", "Dimension Code" = Analysis_View."Dimension 1 Code";
                    column(DimVal1; "Dimension Value Code")
                    {
                    }
                    dataitem(DimSet2; "Dimension Set Entry")
                    {
                        DataItemLink = "Dimension Set ID" = SlgC_Cash_G_L_Entry."Dimension Set ID", "Dimension Code" = Analysis_View."Dimension 2 Code";
                        column(DimVal2; "Dimension Value Code")
                        {
                        }
                        dataitem(DimSet3; "Dimension Set Entry")
                        {
                            DataItemLink = "Dimension Set ID" = SlgC_Cash_G_L_Entry."Dimension Set ID", "Dimension Code" = Analysis_View."Dimension 3 Code";
                            column(DimVal3; "Dimension Value Code")
                            {
                            }
                            dataitem(DimSet4; "Dimension Set Entry")
                            {
                                DataItemLink = "Dimension Set ID" = SlgC_Cash_G_L_Entry."Dimension Set ID", "Dimension Code" = Analysis_View."Dimension 4 Code";
                                column(DimVal4; "Dimension Value Code")
                                {
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

