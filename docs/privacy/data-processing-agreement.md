# Data processing agreement

*Template, based on the processor terms required by UK GDPR Article 28(3). To be reviewed by the school's DPO and a solicitor before signature. Replace the items in [square brackets].*

**Between**

- **[School or trust name]**, [address], URN [number] (the **Controller**), and
- **[Operator name]**, [address], company number [number] (the **Processor**).

**Date:** [date]

## 1. Subject matter and duration

The Processor provides SPAG Buddy, an iPad app and teacher website for practising spelling, punctuation and grammar (the **Service**). This agreement applies for as long as the Controller uses the Service, and until all Controller personal data has been deleted or returned under clause 10.

## 2. Nature and purpose of processing

Storing pupils' practice answers so that the app can choose suitable questions, and so that teachers can see progress and set work. Authenticating teachers and pupils. Nothing else.

## 3. Personal data and data subjects

| Data subjects | Personal data |
| --- | --- |
| Pupils aged 4 to 11 | First name or nickname; avatar picture; hashed PIN; class and year group; practice answers with correctness, time taken, hint use and timestamps; hashed device token |
| Teachers and school staff | Name; school email address; school name and URN; class memberships; audit log of deletions and PIN resets |

No special category data or criminal offence data is processed. The Controller must not enter surnames, dates of birth, UPNs or other identifiers in pupil name fields; the Service rejects names containing digits or @.

## 4. Processor obligations

The Processor will:

1. process personal data only on the Controller's documented instructions, which are this agreement and the Controller's use of the Service's settings, unless UK law requires otherwise (in which case it will tell the Controller first unless the law prohibits this);
2. make sure everyone authorised to process the data is bound by confidentiality;
3. take the security measures in Schedule 1;
4. not engage another processor without the Controller's general written authorisation. The Controller authorises the sub-processors in Schedule 2. The Processor will give at least 30 days' notice of changes, and the Controller may object on reasonable data protection grounds. The Processor will impose the same data protection obligations on sub-processors and remains liable for them;
5. help the Controller respond to data subject requests, including by providing the CSV export, rename and deletion features in the Service, and respond to any request it receives directly by passing it to the Controller within 5 working days;
6. help the Controller with security, breach notification, DPIAs and prior consultation with the ICO, taking into account the nature of the processing;
7. notify the Controller without undue delay, and within 24 hours of becoming aware, of any personal data breach affecting Controller data, with the information in Article 33(3) as it becomes available;
8. at the end of the Service, delete all Controller personal data (or return it as CSV if asked) within 30 days, and confirm this in writing, unless UK law requires storage;
9. make available all information needed to show compliance with Article 28, and allow for and contribute to audits, including inspections, by the Controller or an auditor it appoints, on reasonable notice;
10. tell the Controller immediately if it thinks an instruction infringes data protection law.

## 5. Controller obligations

The Controller will:

1. have a lawful basis for the processing and tell pupils and parents about it (a template notice is provided);
2. enter only the data the Service needs;
3. keep teacher accounts secure and remove staff who leave;
4. archive or delete classes when pupils leave.

## 6. International transfers

Data is hosted in [the UK (London) / the EU] region. Where a sub-processor may access data from outside the UK, the Processor will make sure an appropriate safeguard under UK GDPR Chapter V is in place, such as the UK International Data Transfer Addendum or the UK Extension to the EU-US Data Privacy Framework.

## 7. Liability

[To be agreed. Usually capped at the fees paid in the previous 12 months, except for breaches of data protection law caused by the Processor's failure to follow this agreement.]

## 8. Governing law

This agreement is governed by the law of England and Wales.

---

## Schedule 1: Security measures

- All traffic is encrypted with TLS. Data at rest is encrypted by the hosting provider.
- Row Level Security in the database: teachers can only read classes they belong to; pupils never query the database directly.
- Pupil PINs are hashed with bcrypt. Device tokens are 32 random bytes and only their SHA-256 hash is stored.
- Pupil sign-in locks for 15 minutes after 5 wrong PINs, and a class stops accepting sign-ins for 15 minutes after 30 failures.
- Teachers sign in with single-use email links; there are no passwords to reuse.
- The service-role database key is held only by the API function and never sent to browsers or iPads.
- CSV exports escape cells so pupils' typed answers cannot run as spreadsheet formulas.
- Deletions and PIN resets are logged.
- Automatic deletion under the retention policy.
- Processor staff access production data only to investigate a problem reported by the Controller, and record each access.

## Schedule 2: Authorised sub-processors

| Sub-processor | Service | Location |
| --- | --- | --- |
| Supabase Inc. | Database, authentication, API hosting | [region] |
| [Email provider] | Teacher sign-in emails | [location] |
