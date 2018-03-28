# Change Log

## [2.2.2](https://github.com/zammad/zammad/tree/2.2.2) (2018-03-29)
[Full Changelog](https://github.com/zammad/zammad/compare/2.2.1...2.2.2)

**Fixed bugs:**
- The column widths of a table are shifted after manual change and use of pagination. [\#1829](https://github.com/zammad/zammad/issues/1829) [[bug](https://github.com/zammad/zammad/labels/bug)]
- XSS issue in ticket overview [\#1869](https://github.com/zammad/zammad/issues/1869) [[bug](https://github.com/zammad/zammad/labels/bug)]

## [2.2.1](https://github.com/zammad/zammad/tree/2.2.0) (2018-01-30)
[Full Changelog](https://github.com/zammad/zammad/compare/2.2.0...2.2.1)

**Fixed bugs:**
- Generated excel report fails to create for special strings in ticket titles \(also: CSV formula injection possible\) [\#1756](https://github.com/zammad/zammad/issues/1756) [[bug](https://github.com/zammad/zammad/labels/bug)] [[reporting](https://github.com/zammad/zammad/labels/reporting)]
- Need data\_option\[:null\] - Ticket Object Manager [\#1742](https://github.com/zammad/zammad/issues/1742) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Ticket search fails for limit exceeding 100 with internal server error [\#1753](https://github.com/zammad/zammad/issues/1753) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to send auto reply if from contains 2 or more senders with invalid email address [\#1749](https://github.com/zammad/zammad/issues/1749) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Report for Created tickets should not have "merged" tickets [\#1741](https://github.com/zammad/zammad/issues/1741) [[bug](https://github.com/zammad/zammad/labels/bug)] [[reporting](https://github.com/zammad/zammad/labels/reporting)]
- Wrong ticket number count in preview [\#1723](https://github.com/zammad/zammad/issues/1723) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Zammad Api for idoit.object\_ids broken [\#1711](https://github.com/zammad/zammad/issues/1711) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to login with Office365 [\#1710](https://github.com/zammad/zammad/issues/1710) [[bug](https://github.com/zammad/zammad/labels/bug)]
- No user preference for out-of-office available [\#1699](https://github.com/zammad/zammad/issues/1699) [[bug](https://github.com/zammad/zammad/labels/bug)]
- SipgateController - undefined method `each' for nil:NilClass \(NoMethodError\) [\#1698](https://github.com/zammad/zammad/issues/1698) [[bug](https://github.com/zammad/zammad/labels/bug)]

## [2.2.0](https://github.com/zammad/zammad/tree/2.2.0) (2017-12-06)
[Full Changelog](https://github.com/zammad/zammad/compare/2.1.0...2.2.0)

**Implemented enhancements:**
- email forward of article \(like regular email client forward - e. g. forward customers message to third party contact\) [\#573](https://github.com/zammad/zammad/issues/573) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Take over attachment on ticket split [\#195](https://github.com/zammad/zammad/issues/195) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Enable state "merged" for admin overviews, triggers and jobs [\#1689](https://github.com/zammad/zammad/issues/1689) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Elasticsearchs mapper-attachments plugin has been deprecated, use ingest-attachment now [\#599](https://github.com/zammad/zammad/issues/599) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Improve i-doit filtering \(without type\) [\#1571](https://github.com/zammad/zammad/issues/1571) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Reset customer selection in ticket create screen if input field cleared [\#1670](https://github.com/zammad/zammad/issues/1670) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Add config option for intelligent customer selection of incoming emails of agents [\#1671](https://github.com/zammad/zammad/issues/1671) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Twitter: Allow tweet articles to be 280 chars long [\#1628](https://github.com/zammad/zammad/issues/1628) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Chat language setting or behaviour in dutch [\#1618](https://github.com/zammad/zammad/issues/1618) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- leading and tailing utf8 spaces are not removed for email addresses are not removed [\#1579](https://github.com/zammad/zammad/issues/1579) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Import emails with same message\_id but target was different channels [\#1578](https://github.com/zammad/zammad/issues/1578) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]

**Fixed bugs:**
- Webform isn´t available | 401 Unauthorized [\#1604](https://github.com/zammad/zammad/issues/1604) [[bug](https://github.com/zammad/zammad/labels/bug)]
- TimeAccounting ticket condition prevents submit of Zoom [\#1513](https://github.com/zammad/zammad/issues/1513) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to re-order overviews in admin interface with over 100 overviews [\#1681](https://github.com/zammad/zammad/issues/1681) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to open trigger in admin interface [\#1666](https://github.com/zammad/zammad/issues/1666) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Users mail\_delivery\_failed is not removed after changing the email address [\#1661](https://github.com/zammad/zammad/issues/1661) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Tickets are deleted but database is still the same size [\#1649](https://github.com/zammad/zammad/issues/1649) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Translation for form widget in Dutch [\#1623](https://github.com/zammad/zammad/issues/1623) [[enhancement](https://github.com/zammad/zammad/labels/enhancement)]
- Exchange Integration SSL Error with self-signed root certificate authority  [\#1442](https://github.com/zammad/zammad/issues/1442) [[bug](https://github.com/zammad/zammad/labels/bug)]
- Unable to sort overview by priority  [\#1595](https://github.com/zammad/zammad/issues/1595) [[bug](https://github.com/zammad/zammad/labels/bug)]
- LDAP Integration: Comprehensive configuration cause the import to fail [\#1457](https://github.com/zammad/zammad/issues/1457) [[bug](https://github.com/zammad/zammad/labels/bug)]
- {"error":"Role Customer conflicts with Admin"} [\#1509](https://github.com/zammad/zammad/issues/1509) [[bug](https://github.com/zammad/zammad/labels/bug)]
- prevent admin from locking out [\#1563](https://github.com/zammad/zammad/issues/1563) [[bug](https://github.com/zammad/zammad/labels/bug)]

\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*