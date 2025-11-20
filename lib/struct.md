Event Management App Structure
🔷 Main Entities
1. User (Abstract/Base Class)
Represents any user in the system.

Subclasses:

Admin

Proposer

Reviewer

HOD

All users will have:

id

name

email

role (enum or inferred from class type)

Each role has specific permissions:

Admin: Can configure thresholds, assign roles, manage database.

Proposer: Can create event proposals and view results.

Reviewer: Can propose and review events; suggest changes.

HOD: Can review, approve, reject, or suggest changes; cannot propose.

2. Event
Represents the raw event data submitted by a proposer.

id

title

description

date

startTime

endTime

venue

modeOfEvent (Online/Offline/Hybrid)

typeOfEvent (Seminar, Workshop, etc.)

audienceType (Internal/External/Both)

budget

fundSource

resourcesRequested (List of Strings)

additionalNotes

3. NoteSheet
The metadata wrapper for event processing.

event: Event

proposerId: String

status: EventStatus enum (e.g. PendingReview, UnderReview, ChangesRequested, Approved, Rejected)

reviews: List<ReviewEntry> (contains reviewerId and comment)

acceptedReviewerIds: List<String>

threshold: int

hodDecision: (Optional) object:

hodId

decision: enum HODDecision (Accepted, Rejected, SuggestedChanges)

comment

suggestedChanges: (if any)

rejectionReason: (if any)

4. ReviewEntry (Sub-object inside NoteSheet)
Used to log individual reviewer feedback.

reviewerId: String

comment: String

📦 Additional (Derived/Helper) Objects
EventStatus enum

HODDecision enum

Maybe a Role enum (Admin, Proposer, etc.)