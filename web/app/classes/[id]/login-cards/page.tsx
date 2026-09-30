"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import QRCode from "qrcode";
import { useEffect, useState } from "react";
import { useClass } from "@/components/ClassContext";
import { Empty } from "@/components/ui";
import { avatar } from "@/lib/content";
import { clearLoginCards, loadLoginCards } from "@/lib/login-cards";
import type { LoginCards } from "@/lib/types";

export default function LoginCardsPage() {
  const router = useRouter();
  const { klass, reload } = useClass();
  const [cards, setCards] = useState<LoginCards | null | undefined>(undefined);
  const [codes, setCodes] = useState<Record<string, string>>({});

  useEffect(() => {
    const loaded = loadLoginCards(klass.id);
    setCards(loaded);
    reload();
    if (!loaded) return;
    Promise.all(
      loaded.cards.map(async (card) => [card.pupilId, await QRCode.toDataURL(card.joinUrl, { margin: 1, width: 208, errorCorrectionLevel: "M" })] as const),
    ).then((entries) => setCodes(Object.fromEntries(entries)));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [klass.id]);

  function done() {
    clearLoginCards(klass.id);
    router.push(`/classes/${klass.id}/pupils`);
  }

  if (cards === undefined) return null;
  if (!cards) {
    return (
      <div className="card">
        <Empty>
          <h2>No login cards to print</h2>
          <p>For safety, PINs are only shown once. Make new cards from the Pupils page.</p>
          <Link className="btn" href={`/classes/${klass.id}/pupils`}>
            Back to pupils
          </Link>
        </Empty>
      </div>
    );
  }

  return (
    <>
      <div className="no-print">
        <div className="crumbs">
          <Link href="/classes">Classes</Link> / <Link href={`/classes/${klass.id}/pupils`}>{klass.name}</Link> / Login cards
        </div>
        <div className="page-head">
          <div>
            <h1>Login cards for {cards.className}</h1>
            <p>
              Print these now. The PINs will not be shown again once you leave this page. Pupils scan the QR code with the iPad camera, or type
              the class code, tap their picture and enter their PIN.
            </p>
          </div>
          <div className="row">
            <button className="btn" type="button" onClick={() => window.print()}>
              Print cards
            </button>
            <button className="btn secondary" type="button" onClick={done}>
              Done, clear PINs
            </button>
          </div>
        </div>
      </div>
      <div className="login-cards">
        {cards.cards.map((card) => {
          const a = avatar(card.avatarKey);
          return (
            <article key={card.pupilId} className="login-card" aria-label={`Login card for ${card.displayName}`}>
              <div>
                <div className="big-emoji" aria-hidden>
                  {a.emoji}
                </div>
                <div className="name">{card.displayName}</div>
                <dl>
                  <dt>Class code</dt>
                  <dd className="code">{cards.classCode}</dd>
                  <dt>My picture</dt>
                  <dd>{a.name}</dd>
                  <dt>My PIN</dt>
                  <dd className="code">{card.pin}</dd>
                </dl>
              </div>
              {codes[card.pupilId] ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={codes[card.pupilId]} alt={`QR code to sign ${card.displayName} in`} />
              ) : (
                <span style={{ width: 104 }} />
              )}
            </article>
          );
        })}
      </div>
      <p className="small muted" style={{ marginTop: "1rem" }}>
        Keep cards in class. Only a first name is printed. If a card is lost, make a new PIN from the Pupils page.
      </p>
    </>
  );
}
