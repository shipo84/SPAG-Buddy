import type { Metadata } from "next";
import { TopBar } from "@/components/TeacherShell";

export const metadata: Metadata = { title: "Privacy and data" };

export default function Privacy() {
  return (
    <>
      <TopBar />
      <main className="page" style={{ maxWidth: 820 }}>
        <h1>Privacy and data</h1>
        <p className="muted">
          A summary for teachers. Your school is the data controller and SPAG Buddy is the processor. The full school privacy notice, data
          processing agreement and DPIA template are in the <code>docs/privacy</code> folder of the project.
        </p>

        <section className="card">
          <h2>What we keep about pupils</h2>
          <ul>
            <li>A first name or nickname that you type, and the animal picture we give them.</li>
            <li>Which class they are in.</li>
            <li>Their answers: the question, what they typed or tapped, whether it was right, how long it took and whether they used a hint.</li>
            <li>A 4-digit PIN, stored only as a scrambled hash. We cannot read it back.</li>
          </ul>
          <p>
            We never ask for surnames, dates of birth, UPNs, emails, photos or location. Pupils cannot chat, share or see other pupils&apos;
            results, and there are no adverts or tracking.
          </p>
        </section>

        <section className="card">
          <h2>Where it is stored</h2>
          <p>In a database in the UK or EU. The iPad keeps answers on the device until it can send them, then sends them over an encrypted connection.</p>
        </section>

        <section className="card">
          <h2>How long we keep it</h2>
          <ul>
            <li>Answers are deleted automatically 24 months after they were given.</li>
            <li>Archived classes are deleted with all pupils and answers 12 months after archiving.</li>
            <li>You can delete a pupil or a whole class at any time from this site. Deletion is immediate and permanent.</li>
            <li>Teacher actions such as deleting pupils are logged for 24 months for security.</li>
          </ul>
        </section>

        <section className="card">
          <h2>Requests from parents</h2>
          <p>
            To answer a subject access request, open the class, choose <strong>Download answers (CSV)</strong> with the date range &ldquo;This
            school year&rdquo;, and filter to the pupil. To erase a pupil&apos;s data, delete them from the Pupils tab.
          </p>
        </section>
      </main>
    </>
  );
}
