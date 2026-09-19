# auditsense
1. internal audit platform used for accouting firm in a organization for analyzing the financial statments, flag analmolies and draft audit finiding. 

2. it need to have LLM service to summarize the transaction records, cross refer the exisitng general ledger entries against the supporting documents, and give the narrative secitons of audit reports for human reviews to approve. 

3. supporting documents may be scanned papers, pdfs, large excel spreadsheets and large document size of any kind. 

4. the model either shared or public, should be train on sample data and should not have any customer or engagement data 

5. audit trail record - the response from the LLM should be consistent, the response should be in-memory for any outage that occur during the retrieval process

6. model used should be tracked for every prompt and responses. 

7. Human approver is required for every response that the AI is generated or drafted before its been published as audit workpaper. 

8. the application should also support integrating with exisitng knowledge base that the org has. 
